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
observeMentionDeletion();

function getMentionBeforeCaret() {
    const selection = window.getSelection();
    if (!selection || selection.rangeCount === 0) return null;
    const range = selection.getRangeAt(0);
    if (!range.collapsed) return null;

    const node = range.startContainer;
    const offset = range.startOffset;

    const isAtTextStart =
        node.nodeType === Node.TEXT_NODE &&
        node.textContent.slice(0, offset).replace(/\u200B/g, "").length === 0;

    let probe = null;
    if (isAtTextStart) {
        probe = node.previousSibling;
    } else if (node.nodeType === Node.ELEMENT_NODE && offset > 0) {
        probe = node.childNodes[offset - 1];
    }

    while (probe && probe.nodeType === Node.TEXT_NODE &&
           probe.textContent.replace(/\u200B/g, "").length === 0) {
        probe = probe.previousSibling;
    }

    return probe && probe.nodeType === Node.ELEMENT_NODE &&
           probe.matches?.("a[data-ik-mention-ref]") ? probe : null;
}



function handleMentionBackspace(event) {
    if (event.key !== "Backspace") return;

    const mention = getMentionBeforeCaret();
    if (!mention) return;

    event.preventDefault();

    const range = document.createRange();
    range.setStartBefore(mention);
    range.collapse(true);
    
    let allMentions = document.querySelectorAll("a[data-ik-mention-ref]");
    if (allMentions.length <= 1) {
        let br = document.createElement("br");
        mention.replaceWith(br);
    }else {
        mention.remove();
    }

    const selection = window.getSelection();
    selection.removeAllRanges();
    selection.addRange(range);
}


function observeMentionDeletion() {
    const extractRemovedRefs = (node, refsCollection) => {
        if (node.nodeType === Node.ELEMENT_NODE && node.hasAttribute("data-ik-mention-ref")) {
            refsCollection.push(node.getAttribute("data-ik-mention-ref"));
        }

        if (node.nodeType === Node.ELEMENT_NODE) {
            const mentions = node.querySelectorAll("[data-ik-mention-ref]");
            mentions.forEach((mention) => {
                refsCollection.push(mention.getAttribute("data-ik-mention-ref"));
            });
        }
    };

    const setupObserver = () => {
        const rootElement = document.body;
        if (!rootElement) return;

        let pendingRefs = new Set();
        let debounceTimer = null;

        const mutationObserver = new MutationObserver((mutationRecords) => {
            const removedRefs = mutationRecords
                .flatMap(({ removedNodes }) => [...removedNodes])
                .filter((node) => node.nodeType === Node.ELEMENT_NODE)
                .reduce((refs, node) => {
                    extractRemovedRefs(node, refs);
                    return refs;
                }, []);

            removedRefs.forEach((ref) => pendingRefs.add(ref));

            clearTimeout(debounceTimer);

            debounceTimer = setTimeout(() => {
                const actuallyRemovedRefs = [...pendingRefs].filter((ref) => {
                    return !document.querySelector(`[data-ik-mention-ref="${ref}"]`);
                });

                pendingRefs.clear();

                if (actuallyRemovedRefs.length > 0) {
                    onMentionsDeleted(JSON.stringify(actuallyRemovedRefs));
                }
            }, 300);
        });

        mutationObserver.observe(rootElement, { childList: true, subtree: true });
    };

    if (document.body) {
        setupObserver();
    } else {
        document.addEventListener("DOMContentLoaded", setupObserver);
    }
    document.addEventListener("keydown", handleMentionBackspace);
}


function onMentionsDeleted(refsJson) {
    const handler = window.webkit?.messageHandlers?.mentionsDelete;

    if (handler) {
        handler.postMessage(refsJson);
    } else {
        console.warn("WebKit handler is not available.");
    }
}
