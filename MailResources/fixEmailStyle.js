/*
 Infomaniak Mail - iOS App
 Copyright (C) 2022 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

function removeAllProperties() {
    const properties = [
        { name: 'position', values: ['absolute'] },
        { name: '-webkit-text-size-adjust', values: [] }
    ];
    removeCSSProperty(properties);
    return true;
}

function removeCSSProperty(properties) {
    // Remove properties from inline styles
    for (const property of properties) {
        const elementsWithInlineStyle = document.querySelectorAll(`[style*=${property.name}]`);
        for (const element of elementsWithInlineStyle) {
            if (property.values.length === 0 || property.values.includes(element.style[property.name].toLowerCase().trim())) {
                element.style[property.name] = null;
                console.info(`[FIX_EMAIL_STYLE] Remove property ${property.name} from inline style.`);
            }
        }
    }

    // Remove properties from style tag
    for (let i = 0; i < document.styleSheets.length; i++) {
        const styleSheet = document.styleSheets[i];
        try {
            for (let j = 0; j < styleSheet.cssRules.length; j++) {
                for (const property of properties) {
                    if (!styleSheet.cssRules[j].style) { continue; }

                    if (property.values.length === 0 || property.values.includes(styleSheet.cssRules[j].style[property.name].toLowerCase().trim())) {
                        const removedValue = styleSheet.cssRules[j].style?.removeProperty(property.name);
                        if (removedValue) {
                            console.info(`[FIX_EMAIL_STYLE] Remove property ${property.name} from style tag.`);
                        }
                    }
                }
            }
        } catch (exception) {
            // The stylesheet cannot be modified
        }
    }
}
