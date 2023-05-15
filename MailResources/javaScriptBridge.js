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

function reportOverScroll(clientWidth, scrollWidth, messageId) {
    window.webkit.messageHandlers.overScroll.postMessage({ clientWidth, scrollWidth, messageId });
}

function reportError(error, messageId) {
    window.webkit.messageHandlers.error.postMessage({
        errorName: error.name,
        errorMessage: error.message,
        errorStack: error.stack,
        messageId
    });
}

function displayImproved() {
    window.webkit.messageHandlers.displayImproved.postMessage({ });
    return true;
}

function computeMessageContentHeight() {
    const messageContent = document.querySelector(MESSAGE_SELECTOR);
    const messageContentScrollHeight = messageContent.scrollHeight;
    const messageContentZoom = messageContent.style.zoom;

    const documentStyle = window.getComputedStyle(document.body);
    const bodyMarginTop = readSizeFromString(documentStyle["marginTop"]);
    const bodyMarginBottom = readSizeFromString(documentStyle["marginBottom"]);

    const realMailContentSize = messageContentScrollHeight * messageContentZoom;
    const fullBodyHeight = Math.ceil(realMailContentSize + bodyMarginTop + bodyMarginBottom);

    console.log("Content scroll height: " + messageContentScrollHeight);
    console.log("Real mail content size: " + realMailContentSize);
    console.log("Body margin top: " + bodyMarginTop);
    console.log("Body margin bottom: " + bodyMarginBottom);
    console.log("-> Full body height: " + fullBodyHeight);

    return fullBodyHeight;
}

function readSizeFromString(data) {
    const index = data ? data.indexOf('px') : -1;
    if (index == -1) {
        return 0;
    }

    return parseInt(data.slice(0, index), 10);
}
