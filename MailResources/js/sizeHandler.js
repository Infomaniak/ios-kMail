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

function listenToSizeChanges() {
    const observer = new ResizeObserver((entries) => {
        const height = computeMessageContentHeight();
        window.webkit.messageHandlers.sizeChanged.postMessage({ height });
    });

    observer.observe(document.querySelector(MESSAGE_SELECTOR));
    return true;
}

function computeMessageContentHeight() {
    const messageContent = document.querySelector(MESSAGE_SELECTOR);

    // Applying the style `overflow: auto` will help to get the correct height
    // If child elements have margins, then the height of the div will take this into account
    messageContent.style.overflow = 'auto';

    const messageContentScrollHeight = messageContent.scrollHeight;
    const messageContentZoom = parseFloat(messageContent.style.zoom) || 1;

    // Compute body extra size (padding, border, margin)
    const documentStyle = window.getComputedStyle(document.body);
    const extraSizeElements = ['padding', 'border', 'margin',];
    let extraSize = 0;
    for (const element of extraSizeElements) {
        const edges = ['top', 'bottom'];
        for (const edge of edges) {
            const elementSize = readSizeFromString(documentStyle.getPropertyValue(`${element}-${edge}`));
            extraSize += elementSize;
        }
    }

    const realMailContentSize = messageContentScrollHeight * messageContentZoom;
    const fullBodyHeight = Math.ceil(realMailContentSize + extraSize);

    // We can remove the overflow because it's no longer needed
    messageContent.style.overflow = null;

    return fullBodyHeight;
}

function readSizeFromString(data) {
    if (data.indexOf('px') === -1) {
        return 0;
    }
    return parseFloat(data);
}
