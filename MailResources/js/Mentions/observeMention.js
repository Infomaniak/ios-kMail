/*
 Infomaniak Mail - iOS App
 Copyright (C) 2026 Infomaniak Network SA

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

let lastSentValue = null;
let mentionRestartOffset = null;
const validMentionCharsRegex = /^[A-Za-z0-9._+-]*(?:@[A-Za-z0-9.-]*)?$/;
const zeroWidthCharsRegex = /[\u200B-\u200D\uFEFF]/g;
const mentionQueryRegex = /(?:^|\s)@([A-Za-z0-9._+-]*(?:@[A-Za-z0-9.-]*)?)$/;

const getTextBeforeCaret = () => {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) return "";

    const range = selection.getRangeAt(0);
    if (!range.collapsed) return "";

    const preRange = range.cloneRange();
    preRange.selectNodeContents(getEditor());
    preRange.setEnd(range.endContainer, range.endOffset);

    return preRange.toString();
};

const extractMentionQuery = (textBeforeCaret) => {
    const normalizedText = textBeforeCaret.replace(zeroWidthCharsRegex, "");

    if (mentionRestartOffset != null) {
        const mentionStartIndex = normalizedText.lastIndexOf("@");
        if (mentionStartIndex < mentionRestartOffset) return null;

        const queryAfterRestart = normalizedText.slice(mentionStartIndex + 1);
        return validMentionCharsRegex.test(queryAfterRestart) ? queryAfterRestart : null;
    }

    const match = normalizedText.match(mentionQueryRegex);
    if (!match) return null;

    const query = match[1];
    return validMentionCharsRegex.test(query) ? query : null;
};

const isInsideMentionLink = () => {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) return false;

    const range = selection.getRangeAt(0);
    const node = range.startContainer.nodeType === Node.ELEMENT_NODE ? range.startContainer : range.startContainer.parentElement;

    return !!node?.closest("a[data-ik-mention-ref]");
};

const resetMentionQuery = () => {
    if (lastSentValue === null) return;
    lastSentValue = null;
    reportMentionQueryChanged("");
};

const notifyIfChanged = () => {
    if (isInsideMentionLink()) {
        resetMentionQuery();
        return;
    }

    const textBeforeCaret = getTextBeforeCaret();
    const normalizedTextBeforeCaret = textBeforeCaret.replace(zeroWidthCharsRegex, "");
    if (mentionRestartOffset != null && normalizedTextBeforeCaret.length < mentionRestartOffset) {
        mentionRestartOffset = null;
    }
    const query = extractMentionQuery(textBeforeCaret);

    if (query != null && mentionRestartOffset != null) mentionRestartOffset = null;

    if (query === lastSentValue) return;
    lastSentValue = query;

    if (query == null) {
        reportMentionQueryChanged("");
    } else {
        reportMentionQueryChanged(query);
    }
};

const observeMention = () => {
    if (globalThis.__swiftRichHTMLEditorMentionDetectionInitialized) return;
    globalThis.__swiftRichHTMLEditorMentionDetectionInitialized = true;

    document.addEventListener("selectionchange", notifyIfChanged);
    document.addEventListener("input", notifyIfChanged);
    document.addEventListener("keydown", (event) => {
        if (event.key === "Enter") {
            mentionRestartOffset = getTextBeforeCaret().replace(zeroWidthCharsRegex, "").length;
            resetMentionQuery();
        }
    });
};

function reportMentionQueryChanged(query) {
    const handler = window.webkit?.messageHandlers?.mentionQueryDidChange;

    if (handler) {
        handler.postMessage(query);
    }
}

observeMention();
