
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

let lastKnownRange = null;

document.addEventListener('selectionchange', () => {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) return;

    const range = selection.getRangeAt(0);
    const editor = getEditor();
    if (editor && editor.contains(range.commonAncestorContainer)) {
        lastKnownRange = range.cloneRange();
    }
});

function insertHTMLAtCaret(html) {
    const editor = getEditor();
    if (!editor) return false;

    editor.focus();

    const selection = window.getSelection();
    if (lastKnownRange && editor.contains(lastKnownRange.commonAncestorContainer)) {
        selection.removeAllRanges();
        selection.addRange(lastKnownRange);
    } else {
        const range = document.createRange();
        range.selectNodeContents(editor);
        range.collapse(true);
        selection.removeAllRanges();
        selection.addRange(range);
    }

    return document.execCommand('insertHTML', false, html);
}
