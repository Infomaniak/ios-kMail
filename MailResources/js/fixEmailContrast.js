/*
 Infomaniak Mail - iOS App
 Copyright (C) 2025 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

const SRGB_LINEARIZATION = {
    maxChannelValue: 255,
    linearSegmentThreshold: 0.04045,
    linearSegmentDivisor: 12.92,
    gammaOffset: 0.055,
    gammaScale: 1.055,
    gammaExponent: 2.4
};

const SRGB_ENCODING = {
    maxChannelValue: 255,
    linearSegmentThreshold: 0.0031308,
    linearSegmentMultiplier: 12.92,
    gammaScale: 1.055,
    gammaExponent: 2.4,
    gammaOffset: 0.055
};

const RELATIVE_LUMINANCE_WEIGHTS = {
    red: 0.2126,
    green: 0.7152,
    blue: 0.0722
};

const CONTRAST_LUMINANCE_OFFSET = 0.05;

const TEXT_CONTRAST_SETTINGS = {
    preferredContrastRatio: 7,
    darkBackgroundMaxLuminance: 0.1,
    minimumLightTextLuminance: 0.65,
    binarySearchIterations: 24
};

const LINEAR_BLACK_CHANNEL = 0;
const LINEAR_WHITE_CHANNEL = 1;

const EMAIL_BACKGROUND_DARKENING = {
    minimumSourceLuminance: 0.5,
    maximumRgbChannelSpread: 30,
    targetLuminance: 0.006
};

const BACKGROUND_DARKENING_EXCLUDED_TAGS = new Set([
    "SCRIPT",
    "STYLE",
    "IMG",
    "VIDEO",
    "CANVAS"
]);

const TEXT_CONTRAST_EXCLUDED_TAGS = new Set([
    "SCRIPT",
    "STYLE",
    "NOSCRIPT",
    "BR",
    "WBR"
]);

const TEXT_COLOR_PROPERTIES = [
    "color",
    "-webkit-text-fill-color"
];

const EMAIL_DOM_BUDGET = {
    maxElements: 5000,
    maxDepth: 100
};

function srgbChannelToLinearChannel(srgbChannel) {
    const normalizedChannel = srgbChannel / SRGB_LINEARIZATION.maxChannelValue;

    return normalizedChannel <= SRGB_LINEARIZATION.linearSegmentThreshold
        ? normalizedChannel / SRGB_LINEARIZATION.linearSegmentDivisor
        : (
            (normalizedChannel + SRGB_LINEARIZATION.gammaOffset) 
            / SRGB_LINEARIZATION.gammaScale
        ) ** SRGB_LINEARIZATION.gammaExponent;
}

function linearChannelToSrgbChannel(linearChannel) {
    const normalizedSrgbChannel =
        linearChannel <= SRGB_ENCODING.linearSegmentThreshold
            ? linearChannel * SRGB_ENCODING.linearSegmentMultiplier
            : SRGB_ENCODING.gammaScale
                * (linearChannel ** (1 / SRGB_ENCODING.gammaExponent))
                - SRGB_ENCODING.gammaOffset;

    return clampAndRoundSrgbChannel( normalizedSrgbChannel * SRGB_ENCODING.maxChannelValue );
}

function clampAndRoundSrgbChannel(srgbChannel) {
    const clampedChannel = Math.max( 0, Math.min(SRGB_ENCODING.maxChannelValue, srgbChannel));
    return Math.round(clampedChannel);
}

function linearRgbToRelativeLuminance([linearRed, linearGreen, linearBlue]) {
    return (
        linearRed * RELATIVE_LUMINANCE_WEIGHTS.red
        + linearGreen * RELATIVE_LUMINANCE_WEIGHTS.green
        + linearBlue * RELATIVE_LUMINANCE_WEIGHTS.blue
    );
}

function relativeLuminancesToContrastRatio(relativeLuminanceA, relativeLuminanceB) {
    const lighterLuminance = Math.max(relativeLuminanceA, relativeLuminanceB);
    const darkerLuminance = Math.min(relativeLuminanceA, relativeLuminanceB);

    return (
        (lighterLuminance + CONTRAST_LUMINANCE_OFFSET)
        / (darkerLuminance + CONTRAST_LUMINANCE_OFFSET)
    );
}

function findCorrectedTextRgb(foregroundRgb, backgroundRgb) {
    const foregroundLinearRgb = foregroundRgb.map(srgbChannelToLinearChannel);
    const backgroundLinearRgb = backgroundRgb.map(srgbChannelToLinearChannel);

    const foregroundLuminance = linearRgbToRelativeLuminance(foregroundLinearRgb);
    const backgroundLuminance = linearRgbToRelativeLuminance(backgroundLinearRgb);

    const targetContrastRatio = getTargetTextContrastRatio(backgroundLuminance);
    const currentContrastRatio = relativeLuminancesToContrastRatio(foregroundLuminance, backgroundLuminance);

    if (currentContrastRatio >= targetContrastRatio) { return null; }

    const correctedLinearRgb =
        backgroundLuminance <= TEXT_CONTRAST_SETTINGS.darkBackgroundMaxLuminance
            ? lightenTextForDarkBackground(
                foregroundLinearRgb,
                foregroundLuminance,
                backgroundLuminance,
                targetContrastRatio
            )
            : findLeastMixedTextColor(
                foregroundLinearRgb,
                backgroundLuminance,
                targetContrastRatio
            );

    return correctedLinearRgb === null
        ? null
        : correctedLinearRgb.map(linearChannelToSrgbChannel);
}

function getTargetTextContrastRatio(backgroundLuminance) {
    const blackContrastRatio = relativeLuminancesToContrastRatio(LINEAR_BLACK_CHANNEL, backgroundLuminance);
    const whiteContrastRatio = relativeLuminancesToContrastRatio(LINEAR_WHITE_CHANNEL, backgroundLuminance);
    const maximumContrastRatio = Math.max(blackContrastRatio, whiteContrastRatio);

    return Math.min(TEXT_CONTRAST_SETTINGS.preferredContrastRatio, maximumContrastRatio);
}

function lightenTextForDarkBackground(
    foregroundLinearRgb,
    foregroundLuminance,
    backgroundLuminance,
    targetContrastRatio
) {
    const requiredTextLuminance =
        targetContrastRatio * (backgroundLuminance + CONTRAST_LUMINANCE_OFFSET)
        - CONTRAST_LUMINANCE_OFFSET;

    const targetTextLuminance = Math.min(
        LINEAR_WHITE_CHANNEL,
        Math.max(
            TEXT_CONTRAST_SETTINGS.minimumLightTextLuminance,
            requiredTextLuminance
        )
    );

    if (foregroundLuminance >= targetTextLuminance) { return null; }

    const mixAmount =
        (targetTextLuminance - foregroundLuminance)
        / (LINEAR_WHITE_CHANNEL - foregroundLuminance);

    return mixLinearRgbTowardEndpoint(
        foregroundLinearRgb,
        LINEAR_WHITE_CHANNEL,
        mixAmount
    );
}

function mixLinearRgbTowardEndpoint(linearRgb, endpointChannel, mixAmount) {
    return linearRgb.map(
        linearChannel =>
            linearChannel + (endpointChannel - linearChannel) * mixAmount
    );
}

function findTextMixCandidate(
    foregroundLinearRgb,
    backgroundLuminance,
    targetContrastRatio,
    endpointChannel
) {
    const endpointContrastRatio = relativeLuminancesToContrastRatio(
        endpointChannel,
        backgroundLuminance
    );

    if (endpointContrastRatio < targetContrastRatio) {
        return null;
    }

    let lowerMixAmount = 0;
    let upperMixAmount = 1;

    for (
        let iteration = 0;
        iteration < TEXT_CONTRAST_SETTINGS.binarySearchIterations;
        iteration++
    ) {
        const middleMixAmount = (lowerMixAmount + upperMixAmount) / 2;

        const mixedLinearRgb = mixLinearRgbTowardEndpoint(
            foregroundLinearRgb,
            endpointChannel,
            middleMixAmount
        );

        const mixedLuminance = linearRgbToRelativeLuminance(mixedLinearRgb);

        const mixedContrastRatio = relativeLuminancesToContrastRatio(
            mixedLuminance,
            backgroundLuminance
        );

        if (mixedContrastRatio >= targetContrastRatio) {
            upperMixAmount = middleMixAmount;
        } else {
            lowerMixAmount = middleMixAmount;
        }
    }

    return {
        mixAmount: upperMixAmount,
        linearRgb: mixLinearRgbTowardEndpoint(
            foregroundLinearRgb,
            endpointChannel,
            upperMixAmount
        )
    };
}

function findLeastMixedTextColor(
    foregroundLinearRgb,
    backgroundLuminance,
    targetContrastRatio
) {
    const blackCandidate = findTextMixCandidate(
        foregroundLinearRgb,
        backgroundLuminance,
        targetContrastRatio,
        LINEAR_BLACK_CHANNEL
    );

    const whiteCandidate = findTextMixCandidate(
        foregroundLinearRgb,
        backgroundLuminance,
        targetContrastRatio,
        LINEAR_WHITE_CHANNEL
    );

    if (blackCandidate === null) {
        return whiteCandidate?.linearRgb ?? null;
    }

    if (whiteCandidate === null) {
        return blackCandidate.linearRgb;
    }

    return whiteCandidate.mixAmount < blackCandidate.mixAmount
        ? whiteCandidate.linearRgb
        : blackCandidate.linearRgb;
}

function parseCommaSeparatedRgbColor(colorString) {
    if (!colorString) { return null; }

    const colorMatch = colorString.trim().match(/^rgba?\(([^)]+)\)$/i);
    if (!colorMatch) { return null; }

    const components = colorMatch[1].split(",").map(component => Number(component.trim()));
    if (!hasValidRgbComponentStructure(components)) { return null; }

    const [red, green, blue, alpha = 1] = components;
    return { rgb: [red, green, blue], alpha };
}

function hasValidRgbComponentStructure(components) {
    const hasExpectedComponentCount = components.length === 3 || components.length === 4;
    return hasExpectedComponentCount && components.every(Number.isFinite);
}

const emailContrastStyleHistory = new Map();

function restoreEmailContrastStyles() {
    for (const [element, savedProperties] of emailContrastStyleHistory) {
        for (const savedProperty of savedProperties) {
            restoreInlineStylePropertyIfUnchanged(element, savedProperty);
        }
    }

    emailContrastStyleHistory.clear();
}

function restoreInlineStylePropertyIfUnchanged(element, savedProperty) {
    const currentValue = element.style.getPropertyValue(savedProperty.name);

    if (currentValue !== savedProperty.appliedValue) { return; }

    if (savedProperty.value === "") {
        element.style.removeProperty(savedProperty.name);
        return;
    }

    element.style.setProperty(
        savedProperty.name,
        savedProperty.value,
        savedProperty.priority
    );
}

function findOpaqueBackgroundRgb(element, getStyleForElement) {
    for (
        let currentElement = element;
        currentElement;
        currentElement = currentElement.parentElement
    ) {
        const computedStyle = getStyleForElement(currentElement);

        if (computedStyle.backgroundImage !== "none") { return null; }

        const backgroundColor = parseCommaSeparatedRgbColor(computedStyle.backgroundColor);

        if (!backgroundColor) { return null; }
        if (backgroundColor.alpha === 1) { return backgroundColor.rgb; }
        if (backgroundColor.alpha !== 0) { return null; }
    }
    return null;
}

function darkenLightNeutralEmailBackgrounds(getStyleForElement, result) {
    const backgroundChanges = collectEmailBackgroundChanges(getStyleForElement);

    for (const { element, color } of backgroundChanges) {
        applyTrackedEmailBackgroundColor(element, color);
        result.backgroundsDarkened++;
    }
}

function collectEmailBackgroundChanges(getStyleForElement) {
    const backgroundChanges = [];
    const elements = [document.documentElement, document.body, ...document.body.querySelectorAll("*")];

    for (const element of elements) {
        const darkenedRgb = getDarkenedBackgroundRgb(element, getStyleForElement);

        if (darkenedRgb === null) { continue; }

        backgroundChanges.push({
            element,
            color: `rgb(${darkenedRgb.join(", ")})`
        });
    }

    return backgroundChanges;
}

function getDarkenedBackgroundRgb(element, getStyleForElement) {
    if (BACKGROUND_DARKENING_EXCLUDED_TAGS.has(element.tagName)) { return null; }
    if (element.getClientRects().length === 0) { return null; }

    const computedStyle = getStyleForElement(element);

    if (computedStyle.visibility !== "visible" || computedStyle.backgroundImage !== "none") {
        return null;
    }

    const backgroundColor = parseCommaSeparatedRgbColor(computedStyle.backgroundColor);

    if (!backgroundColor || backgroundColor.alpha !== 1) {  return null; }

    return darkenLightNeutralRgb(backgroundColor.rgb);
}

function darkenLightNeutralRgb(srgbChannels) {
    const linearRgb = srgbChannels.map(srgbChannelToLinearChannel);
    const sourceLuminance = linearRgbToRelativeLuminance(linearRgb);

    const rgbChannelSpread = Math.max(...srgbChannels) - Math.min(...srgbChannels);

    const isLightNeutralColor =
        sourceLuminance >= EMAIL_BACKGROUND_DARKENING.minimumSourceLuminance
        && rgbChannelSpread <= EMAIL_BACKGROUND_DARKENING.maximumRgbChannelSpread;

    if (!isLightNeutralColor) { return null; }

    const luminanceScale = EMAIL_BACKGROUND_DARKENING.targetLuminance / sourceLuminance;

    return linearRgb.map(
        linearChannel =>
            linearChannelToSrgbChannel(linearChannel * luminanceScale)
    );
}

function applyTrackedEmailBackgroundColor(element, color) {
    const savedProperty = {
        name: "background-color",
        value: element.style.getPropertyValue("background-color"),
        priority: element.style.getPropertyPriority("background-color"),
        appliedValue: color
    };

    element.style.setProperty(savedProperty.name, color, "important");

    emailContrastStyleHistory.set(element, [savedProperty]);
}

function isEmailDomWithinBudget() {
    const body = document.body;
    let element = body.firstElementChild;
    let depth = 1;
    let count = 0;

    while (element) {
        count++;
        if (count > EMAIL_DOM_BUDGET.maxElements || depth > EMAIL_DOM_BUDGET.maxDepth) {
            return false;
        }

        if (element.firstElementChild) {
            element = element.firstElementChild;
            depth++;
            continue;
        }

        while (element !== body && !element.nextElementSibling) {
            element = element.parentElement;
            depth--;
        }

        if (element === body) {
            break;
        }

        element = element.nextElementSibling;
    }

    return true;
}

function applyEmailDarkModeContrast() {
    restoreEmailContrastStyles();

    const result = { backgroundsDarkened: 0, examined: 0, corrected: 0, skipped: 0 };

    if (!document.body || !window.matchMedia("(prefers-color-scheme: dark)").matches) {
        return result;
    }

    const getStyleForElement = createCachedStyleGetter();

    if (!isEmailDomWithinBudget()) {
        result.budgetExceeded = true;
        return result;
    }

    darkenLightNeutralEmailBackgrounds(getStyleForElement, result);

    const textColorChanges = collectEmailTextColorChanges(getStyleForElement, result);

    for (const { element, color } of textColorChanges) {
        applyTrackedEmailTextColor(element, color);
        result.corrected++;
    }

    return result;
}

function createCachedStyleGetter() {
    const styleCache = new Map();

    return function getStyleForElement(element) {
        let computedStyle = styleCache.get(element);

        if (!computedStyle) {
            computedStyle = getComputedStyle(element);
            styleCache.set(element, computedStyle);
        }

        return computedStyle;
    };
}

function isTextContrastCandidate(element) {
    if (TEXT_CONTRAST_EXCLUDED_TAGS.has(element.tagName)) { return false; }

    const hasNonEmptyDirectText = Array.from(element.childNodes).some(
        childNode =>
            childNode.nodeType === Node.TEXT_NODE
            && childNode.textContent.trim().length > 0
    );

    return hasNonEmptyDirectText && element.getClientRects().length > 0;
}

function getOpaqueTextAndBackgroundRgb(element, getStyleForElement) {
    const computedStyle = getStyleForElement(element);

    if (computedStyle.visibility !== "visible") { return null; }

    const textColorString = computedStyle.getPropertyValue("-webkit-text-fill-color") || computedStyle.color;
    const textColor = parseCommaSeparatedRgbColor(textColorString);
    const backgroundRgb = findOpaqueBackgroundRgb(element, getStyleForElement);

    if (!textColor || textColor.alpha !== 1 || !backgroundRgb) { return null; }

    return {
        foregroundRgb: textColor.rgb,
        backgroundRgb
    };
}

function collectEmailTextColorChanges(getStyleForElement, result) {
    const textColorChanges = [];
    const elements = [document.body, ...document.body.querySelectorAll("*")];

    for (const element of elements) {
        if (!isTextContrastCandidate(element)) { continue; }

        result.examined++;

        const textAndBackgroundRgb = getOpaqueTextAndBackgroundRgb( element, getStyleForElement  );

        if (textAndBackgroundRgb === null) {
            result.skipped++;
            continue;
        }

        const correctedRgb = findCorrectedTextRgb(
            textAndBackgroundRgb.foregroundRgb,
            textAndBackgroundRgb.backgroundRgb
        );

        if (correctedRgb === null) {
            continue;
        }

        textColorChanges.push({
            element,
            color: `rgb(${correctedRgb.join(", ")})`
        });
    }

    return textColorChanges;
}

function applyTrackedEmailTextColor(element, color) {
    const savedProperties = TEXT_COLOR_PROPERTIES.map(propertyName => {
        const savedProperty = {
            name: propertyName,
            value: element.style.getPropertyValue(propertyName),
            priority: element.style.getPropertyPriority(propertyName),
            appliedValue: color
        };

        element.style.setProperty(propertyName, color, "important");

        return savedProperty;
    });

    const previouslySavedProperties = emailContrastStyleHistory.get(element) || [];

    emailContrastStyleHistory.set(element, [
        ...previouslySavedProperties,
        ...savedProperties
    ]);
}
