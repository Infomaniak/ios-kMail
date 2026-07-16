/*
 * Infomaniak Mail - iOS
 * Copyright (C) 2026 Infomaniak Network SA
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

function movePointerToEndOfMention(event) {
    const mention = event.target.closest(mentionHTML);
    if (mention) {
        event.preventDefault();
        event.stopPropagation();
        // move the caret to the right of the mention
        const selection = window.getSelection();
        const range = document.createRange();
        range.setStartAfter(mention);
        range.collapse(true);
        selection.removeAllRanges();
        selection.addRange(range);
    }
}

document.addEventListener("click", movePointerToEndOfMention, {
    capture: true,
    passive: false,
});
