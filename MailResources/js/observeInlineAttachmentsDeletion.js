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
    const CID_PREFIX = "cid:";

    const isCidImage = (img) => img.src.startsWith(CID_PREFIX);
    const isDataCidImage = (img) => img.hasAttribute("data-cid");

    const getKey = (img) => img.dataset.cid ?? img.src.replace(CID_PREFIX, "");

    const collectCidImages = (node, result) => {
        if (node.tagName?.toLowerCase() === "img") {
            if (isCidImage(node) || isDataCidImage(node)) result.push(node);
        } else {
            result.push(...[...node.getElementsByTagName("img")].filter((img) => isCidImage(img) || isDataCidImage(img)));
        }
    };

    const setupObserver = () => {
        const rootElement = document.body;
        if (!rootElement) return;

        let pendingCids = new Set();
        let debounceTimer = null;

        const mutationObserver = new MutationObserver((mutationRecords) => {
            const removedImgs = [];
            const addedKeys = new Set();

            for (const { removedNodes, addedNodes } of mutationRecords) {
                for (const node of addedNodes) {
                    if (node.nodeType !== Node.ELEMENT_NODE) continue;
                    const imgs = [];
                    collectCidImages(node, imgs);
                    imgs.forEach((img) => addedKeys.add(getKey(img)));
                }
                for (const node of removedNodes) {
                    if (node.nodeType !== Node.ELEMENT_NODE) continue;
                    collectCidImages(node, removedImgs);
                }
            }

            for (const img of removedImgs) {
                const key = getKey(img);
                if (!addedKeys.has(key)) {
                    pendingCids.add(key);
                }
            }

            clearTimeout(debounceTimer);
            debounceTimer = setTimeout(() => {
                const actuallyRemovedCids = [...pendingCids].filter((key) => {
                    const byCid = document.querySelector(`img[src="cid:${key}"]`);
                    const byDataCid = document.querySelector(`img[data-cid="${key}"]`);
                    return !byCid && !byDataCid;
                });
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
