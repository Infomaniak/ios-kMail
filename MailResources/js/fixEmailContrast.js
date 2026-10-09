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

// Converts an sRGB channel (0..255) to linear luminance (0.0..1.0)
// by canceling the gamma curve (IEC 61966-2-1 standard)
function toLinear(channel) {
    const value = channel / 255; // Normalization between 0.0 and 1.0

    return value <= 0.04045
        ? value / 12.92 // Linear segment for deep blacks
        : ((value + 0.055) / 1.055) ** 2.4; // Canceling the gamma power curve
}

// Converts linear light intensity (0.0..1.0) back to sRGB channel (0..255)
// by reapplying the gamma compression curve
function toSRGB(value) {
    const channel = value <= 0.0031308
        ? value * 12.92 // Inverse linear slope near black
        : 1.055 * (value ** (1 / 2.4)) - 0.055; // Gamma re-encoding

    // Scale to [0, 255] and clamp within valid bounds
    return Math.round(Math.max(0, Math.min(255, channel * 255)));
}

// Computes the relative perceived luminance (0.0..1.0) per WCAG 2.1 (BT.709)
// Input channels must be linearized intensities (via toLinear), not raw sRGB 0..255 values
function luminance(linearRGB) {
    // Human spectral sensitivity weights (retinal cone response):
    // - green dominates (~71.5%),
    // - followed by red (~21.3%),
    // - with blue contributing least (~7.2%)
    // The sum of these three constants is exactly 1.0.
    // 0.2126 + 0.7152 + 0.0722 = 1.0, which ensures that pure white has a luminance of 1.0
    return linearRGB[0] * 0.2126 + linearRGB[1] * 0.7152 + linearRGB[2] * 0.0722;
}

// Computes the relative contrast ratio (1:1 to 21:1) per the official WCAG 2.1 formula
// Keep relative luminances (0.0..1.0)
function contrastRatio(lumA, lumB) {
    const lighter = Math.max(lumA, lumB);
    const darker = Math.min(lumA, lumB);
    
    // The 0.05 constant accounts for ambient flare/viewing flare and prevents division by zero
    return (lighter + 0.05) / (darker + 0.05);
}

// Calculates a new text color that is readable against a given background while preserving its original hue as much as possible
// Returns a corrected [R, G, B] triplet (0..255), or null if the original color is already sufficient
function correctedTextColor(foregroundRGB, backgroundRGB) {
    // Conversion to physical linear space for luminance calculations
    const foregroundLinear = foregroundRGB.map(toLinear);
    const backgroundLinear = backgroundRGB.map(toLinear);

    const foregroundLuminance = luminance(foregroundLinear);
    const backgroundLuminance = luminance(backgroundLinear);

/////    const blackContrast = contrastRatio(0, backgroundLuminance);
/////    const whiteContrast = contrastRatio(1, backgroundLuminance);
    // Defining a Realistic Target Contrast
    // A medium-gray background sometimes cannot achieve a 7:1 ratio even when using pure white or black
    const blackContrast = contrastRatio(0, backgroundLuminance);
    const whiteContrast = contrastRatio(1, backgroundLuminance);
    
    
    const targetContrast = Math.min(
                                    7, // Ideal Target: WCAG AAA
                                    Math.max(blackContrast, whiteContrast)); // Maximum physically attainable target

    // If the current contrast is already satisfactory, no changes are needed
    if (contrastRatio(foregroundLuminance, backgroundLuminance) >= targetContrast) { return null; }

    // Very dark background (Classic Dark Mode, luminance <= 0.1)
    if (backgroundLuminance <= 0.1) {
        // Requires text that is clearly legible (minimum luminance of 0.65)
        const minimumTextLuminance = 0.65;
        // Mathematical inversion of the WCAG formula: L1 = C * (L2 + 0.05) - 0.05
        const requiredForContrast = targetContrast * (backgroundLuminance + 0.05) - 0.05;
        const targetTextLuminance = Math.min(1, Math.max(minimumTextLuminance, requiredForContrast));

        // If the text is already clear enough, leave it as is
        if (foregroundLuminance >= targetTextLuminance) return null;
        // Calculates the required lightening ratio to achieve pure white
        const amount = (targetTextLuminance - foregroundLuminance) / (1 - foregroundLuminance);
        // Brightens each channel while preserving color balance
        return foregroundLinear.map(channel => toSRGB(channel + (1 - channel) * amount));
    }

    // Search for the Optimal Mix (Dichotomy)
    let best = null;
    
    // We're testing two options: endpoint = 0 (darken toward black), endpoint = 1 (lighten toward white)
    for (const endpoint of [0, 1]) {
        
        // Linear interpolation function (mix): amount = 0 (original color) -> amount = 1 (pure black/white)
        const mix = amount =>
            foregroundLinear.map(channel =>
                channel + (endpoint - channel) * amount
            );

        let lower = 0;
        let upper = 1;

        // 24 iterations allow for convergence with extreme mathematical precision
        for (let iteration = 0; iteration < 24; iteration++) {
            const middle = (lower + upper) / 2;

            if (contrastRatio(luminance(mix(middle)), backgroundLuminance) >= targetContrast) {
                upper = middle; // The contrast is good, trying to alter the color a little less.
            } else {
                lower = middle; // Insufficient contrast, more adjustment is needed
            }
        }
        
        // We choose the solution that alters the original color the least (the smallest amount)
        if (!best || upper < best.amount) {
            best = { amount: upper, color: mix(upper) };
        }
    }

    if (!best) {
        return whiteContrast >= blackContrast ? [255, 255, 255] : [0, 0, 0];
    }

    // Final conversion of linear intensity to CSS sRGB values (0..255)
    return best.color.map(toSRGB);
}

// Parses a CSS color string standardized by WebKit (e.g. rgb(34, 34, 34)
// and returns a structured object { rgb: [r, g, b], alpha: a }, or null if the value is invalid
function parseEmailColor(val) {
    if (!val) return null;
    
    // Regular expression to capture the content within parentheses in a format
    const match = val.trim().match(/^rgba?\(([^)]+)\)$/i);
    if (!match) return null;

    // Parsing the comma-separated components and converting them to numbers
    const parts = match[1].split(",").map(p => Number(p.trim()));
    
    // Structure validation: size 3 or 4, and no element may be NaN or Infinity
    if ((parts.length !== 3 && parts.length !== 4) || parts.some(n => !Number.isFinite(n))) {
        return null;
    }

    // Normalized final extraction
    return {
        rgb: parts.slice(0, 3),
        alpha: parts.length === 4 ? parts[3] : 1
    };
}

// Restores the original styles of all elements previously modified by the script
// Allows you to cleanly revert to the light theme without leaving any CSS side effects
const emailContrastOriginalStyles = new Map();

function restoreEmailContrast() {
    // Iterates through all modified DOM elements and their saved styles
    for (const [element, properties] of emailContrastOriginalStyles) {
        for (const property of properties) {
            if (element.style.getPropertyValue(property.name) === property.appliedValue) {
                if (property.value === "") {
                    // The element did not have an inline style before we made our changes (empty property)
                    // We simply remove the inline property to let the original CSS take over
                    element.style.removeProperty(property.name);
                } else {
                    // The element already had a custom inline style
                    // We faithfully restore its original value and priority
                    element.style.setProperty(property.name, property.value, property.priority);
                }
            }
        }
    }
    
    // Clear the change log to start fresh
    emailContrastOriginalStyles.clear();
}

// Travels up the DOM tree from a given element to find the first opaque background
// Returns a triplet [R, G, B] (0..255), or null if the background cannot be determined with certainty
function findEmailBackground(element, styleFor) {
    // Traverses the element and then each of its successive ancestors back to the root of the document
    for (let cur = element; cur; cur = cur.parentElement) {
        const style = styleFor(cur);
        
        // Presence of an image or gradient in the background
        // It is impossible to calculate a reliable contrast for a texture or photo using a simple RGB value
        // We skip this step to avoid choosing the wrong text color
        if (style.backgroundImage !== "none") return null;

        // Extraction and Validation of the Background Color
        const bg = parseEmailColor(style.backgroundColor);
        if (!bg) return null;

        // If a completely opaque background is found:
        // This is our solid reference surface, we immediately return its [R, G, B] triplet
        
        if (bg.alpha === 1) return bg.rgb;
        if (bg.alpha !== 0) return null; // Ignores non-composite semi-transparent backgrounds
        // If bg.alpha === 0 (purely transparent, the most common case for an inline container):
        // The loop naturally continues to the next parent (cur = cur.parentElement).
    }
    return null;
}

// Darkens light-colored surfaces (mail backgrounds)
function darkenEmailBackgrounds(styleFor, result) {
    const changes = [];
    // Exhaustive traversal: root <html>, body <body>, and all descendants
    // The hierarchical order ensures that parent containers are processed before their children
    const elements = [document.documentElement, document.body, ...document.body.querySelectorAll("*")];

    // Filtering and Calculating New Colors (Read-Only)
    for (const element of elements) {
        // Ignore technical tags
        if (["SCRIPT", "STYLE", "IMG", "VIDEO", "CANVAS"].includes(element.tagName)) continue;
        // Ignore elements that are not rendered or are invisible
        if (element.getClientRects().length === 0) continue;

        const style = styleFor(element);
        // Ignore elements that are hidden or already have a background pattern or image
        if (style.visibility !== "visible" || style.backgroundImage !== "none") continue;

        // Analyze the calculated CSS color: invalid or transparent backgrounds are ignored
        const bg = parseEmailColor(style.backgroundColor);
        if (!bg || bg.alpha !== 1) continue;

        // Conversion to physical linear intensities and calculation of relative luminance (0..1)
        const linear = bg.rgb.map(toLinear);
        const bright = luminance(linear);
        // Measures perceived saturation: the difference in intensity between the strongest and weakest channels
        // A perfect gray has a spread of 0, a vive color (pure red [255, 0, 0]) will have a spread of 255
        const spread = Math.max(...bg.rgb) - Math.min(...bg.rgb);

        // Select only backgrounds that are nearly white or light gray
        if (bright >= 0.5 && spread <= 30) {
            // Calculates the light intensity reduction factor
            // The constant 0.006 targets a very dark final luminance (~0.6% reflectance)
            // Dividing by `bright` normalizes the reduction so that all light backgrounds converge to a uniform baseline
            const factor = 0.006 / bright;
            // Applies the factor to the linear channels and then converts them to sRGB values (0..255)
            const darkRGB = linear.map(channel => toSRGB(channel * factor));
            // Saves the change to be applied without immediately modifying the DOM
            changes.push({ element, color: `rgb(${darkRGB.join(", ")})` });
        }
    }

    // DOM Mutation and History Preservation (Writing)
    for (const { element, color } of changes) {
        // Captures the original inline state to allow undoing via `restoreEmailContrast`
        const prop = {
            name: "background-color",
            value: element.style.getPropertyValue("background-color"),
            priority: element.style.getPropertyPriority("background-color"),
            appliedValue: color
        };
        // Forces the dark theme to be applied with the highest priority
        element.style.setProperty(prop.name, color, "important");
        // Saves the item to the global rollback registry
        emailContrastOriginalStyles.set(element, [prop]);
        // Increments the statistics counter
        result.backgroundsDarkened++;
    }
}

// Main entry point for adjusting email text contrast and backgrounds
// Coordinates style rollback, background dimming, and text color correction
function fixEmailContrast() {
    // Remove previous mutations to ensure clean evaluation against original DOM
    restoreEmailContrast();

    const result = { backgroundsDarkened: 0, examined: 0, corrected: 0, skipped: 0 };

    // Valid <body> element and system dark mode actively requested
    if (!document.body || !window.matchMedia("(prefers-color-scheme: dark)").matches) {
        return result;
    }

    // Computed style memoization cache
    const styleCache = new Map();
    const styleFor = (element) => {
        let s = styleCache.get(element);
        if (!s) {
            s = getComputedStyle(element);
            styleCache.set(element, s);
        }
        return s;
    };

    // First pass: darken light email container backgrounds before re-evaluating text contrast
    darkenEmailBackgrounds(styleFor, result);

    const changes = [];
    const elements = document.body.querySelectorAll("*");

    // Identify text leaf nodes and calculate needed contrast adaptations
    for (const element of elements) {
        // Skip technical scripts, styles, and structural line break tags
        if (["SCRIPT", "STYLE", "NOSCRIPT", "BR", "WBR"].includes(element.tagName)) continue;

        // Verify presence of non-empty direct text content (avoids processing wrapper parents repeatedly)
        const hasText = Array.from(element.childNodes).some(
            n => n.nodeType === Node.TEXT_NODE && n.textContent.trim().length > 0
        );

        // Skip elements without direct text or with empty bounding boxes (display: none / detached)
        if (!hasText || element.getClientRects().length === 0) continue;

        result.examined++;

        const style = styleFor(element);
        if (style.visibility !== "visible") {
            result.skipped++;
            continue;
        }

        // Read effective text color, accounting for WebKit text fill overrides
        const fg = parseEmailColor(style.getPropertyValue("-webkit-text-fill-color") || style.color);

        // Traverse upwards to resolve the effective opaque background behind this node
        const bgRGB = findEmailBackground(element, styleFor);

        // Skip non-opaque foregrounds, unparsable formats, or ambiguous backgrounds (e.g. images)
        if (!fg || fg.alpha !== 1 || !bgRGB) {
            result.skipped++;
            continue;
        }

        // Determine adjusted color if WCAG ratio is insufficient
        const corrected = correctedTextColor(fg.rgb, bgRGB);
        if (!corrected) continue; // null indicates contrast is already compliant

        changes.push({ element, color: `rgb(${corrected.join(", ")})` });
    }

    // Batched mutation to minimize layout redraws
    for (const { element, color } of changes) {
        // Override both properties to ensure precedence against aggressive Safari/WebKit styling
        const appliedProps = ["color", "-webkit-text-fill-color"].map(name => {
            const entry = {
                name,
                value: element.style.getPropertyValue(name),
                priority: element.style.getPropertyPriority(name),
                appliedValue: color
            };
            element.style.setProperty(name, color, "important");
            return entry;
        });

        // Merge with existing tracked properties (e.g. if the element also had its background adjusted)
        const existing = emailContrastOriginalStyles.get(element) || [];
        emailContrastOriginalStyles.set(element, [...existing, ...appliedProps]);
        result.corrected++;
    }

    return result;
}
