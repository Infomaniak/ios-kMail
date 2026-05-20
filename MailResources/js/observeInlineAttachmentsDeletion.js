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

observeInlineAttachmentsDeletion();

function observeInlineAttachmentsDeletion() {
    const addRemovedCids = (removedNode, removedCids) => {
        const isCidImage = (img) => img.src.startsWith("cid:");

        if (removedNode.tagName.toLowerCase() === "img") {
            if (isCidImage(removedNode)) removedCids.push(removedNode.src);
        } else {
            removedCids.push(...[...removedNode.getElementsByTagName("img")].filter(isCidImage).map((img) => img.src));
        }
    };

    const setupObserver = () => {
        const rootElement = document.body;
        if (!rootElement) return;

        let pendingCids = new Set();
        let debounceTimer = null;

        const mutationObserver = new MutationObserver((mutationRecords) => {
            const removedCids = mutationRecords
                .flatMap(({ removedNodes }) => [...removedNodes])
                .filter((node) => node.nodeType === Node.ELEMENT_NODE)
                .reduce((cids, node) => {
                    addRemovedCids(node, cids);
                    return cids;
                }, []);

            removedCids.forEach((cid) => pendingCids.add(cid));

            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(() => {
                const actuallyRemovedCids = [...pendingCids].filter((cid) => !document.querySelector(`img[src="${cid}"]`));
                pendingCids.clear();

                if (actuallyRemovedCids.length > 0) {
                    onInlineImagesDeleted(JSON.stringify(actuallyRemovedCids));
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
}

function onInlineImagesDeleted(cids) {
    const handler = window.webkit.messageHandlers.inlineAttachmentDelete;

    if (handler) {
        handler.postMessage(cids);
    } else {
        console.warn("WebKit handler is not available.");
    }
}
