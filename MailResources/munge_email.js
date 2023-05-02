const WEBVIEW_WIDTH = 361;
const PREFERENCES = {
    normalizeMessageWidths: true,
    mungeImages: true,
    mungeTables: true,
    minimumEffectiveRatio: 0.7
};

normalizeElementWidths([document.body]);

// Functions

/**
 * Normalizes the width of elements supplied to the document body's overall width.
 * Narrower elements are zoomed in, and wider elements are zoomed out.
 * This method is idempotent.
 * @param elements DOM elements to normalize
 */
function normalizeElementWidths(elements) {
    const documentWidth = document.body.offsetWidth;

    for (const element of elements) {
        // Reset any existing normalization
        const originalZoom = element.style.zoom;
        if (originalZoom) {
            element.style.zoom = 1;
        }

        // Remove textAdjustSize for iOS
        const elementsWithTextSizeAdjust = document.querySelectorAll('[style*=-webkit-text-size-adjust]');
        for (const element of elementsWithTextSizeAdjust) {
            element.style.webkitTextSizeAdjust = null;
        }

        const originalWidth = element.style.width;
        element.style.width = `${WEBVIEW_WIDTH}px`;
        transformContent(element, WEBVIEW_WIDTH, element.scrollWidth);

        if (PREFERENCES.normalizeMessageWidths) {
            const newZoom = documentWidth / element.scrollWidth;
            element.style.zoom = newZoom;
        }

        element.style.width = originalWidth;
    }
}

/**
 *
 * @param element
 * @param documentWidth
 * @param elementWidth
 * @returns
 */
function transformContent(element, documentWidth, elementWidth) {
    if (elementWidth <= documentWidth) { return; }

    let newWidth = elementWidth;
    let isTransformationDone = false;
    /** Format of entries : { function: fn, object: object, arguments: [list of arguments] } */
    let actionsLog = [];

    // Try munging all divs or textareas with inline styles where the width
    // is wider than `documentWidth`, and change it to be a max-width.
    if (PREFERENCES.normalizeMessageWidths) {
        const nodes = element.querySelectorAll('div[style], textarea[style]');
        const areNodesTransformed = transformBlockElements(nodes, documentWidth, actionsLog);
        if (areNodesTransformed) {
            newWidth = element.scrollWidth;
            logTransformation('div-width munger', element, elementWidth, newWidth, documentWidth);
            if (newWidth <= documentWidth) {
                isTransformationDone = true;
            }
        }
    }

    if (!isTransformationDone && PREFERENCES.mungeImages) {
        // OK, that wasn't enough. Find images with widths and override their widths.
        const images = element.querySelectorAll('img');
        const areImagesTransformed = transformImages(images, documentWidth, actionsLog);
        if (areImagesTransformed) {
            newWidth = element.scrollWidth;
            logTransformation('img munger', element, elementWidth, newWidth, documentWidth);
            if (newWidth <= documentWidth) {
                isTransformationDone = true;
            }
        }
    }

    if (!isTransformationDone && PREFERENCES.mungeTables) {
        // OK, that wasn't enough. Find tables with widths and override their widths.
        // Also ensure that any use of 'table-layout: fixed' is negated, since using
        // that with 'width: auto' causes erratic table width.
        const tables = element.querySelectorAll('table');
        const areTablesTransformed = addClassToElements(tables, shouldMungeTable, 'munged', actionsLog);
        if (areTablesTransformed) {
            newWidth = element.scrollWidth;
            logTransformation('table munger', element, elementWidth, newWidth, documentWidth);
            if (newWidth <= documentWidth) {
                isTransformationDone = true;
            }
        }
    }

    if (!isTransformationDone && PREFERENCES.mungeTables) {
        // OK, that wasn't enough. Try munging all <td> to override any width and nowrap set.
        const beforeTransformationWidth = newWidth;
        const tds = element.querySelectorAll('td');
        const tmpActionsLog = [];
        const areTdsTransformed = addClassToElements(tds, null, 'munged', tmpActionsLog);
        if (areTdsTransformed) {
            newWidth = element.scrollWidth;
            logTransformation('td munger', element, elementWidth, newWidth, documentWidth);

            if (newWidth <= documentWidth) {
                isTransformationDone = true;
            } else if (newWidth === beforeTransformationWidth) {
                // This transform did not improve things, and it is somewhat risky.
                // Back it out, since it's the last transform and we gained nothing.
                undoActions(tmpActionsLog);
            } else {
                // The transform WAS effective (although not 100%).
                // Copy the temporary action log entries over as normal.
                actionsLog.push(...tmpActionsLog);
            }
        }
    }

    // If the transformations shrank the width significantly enough, leave them in place.
    // We figure that in those cases, the benefits outweight the risk of rendering artifacts.
    const transformationRatio = (elementWidth - newWidth) / (elementWidth - documentWidth);
    if (!isTransformationDone && transformationRatio > PREFERENCES.minimumEffectiveRatio) {
        logInfo('Transforms deemed effective enough.');
        isTransformationDone = true;
    }

    if (!isTransformationDone) {
        // Reverse all changes if the width is STILL not narrow enough.
        // (except the width->maxWidth change, which is not particularly destructive)
        undoActions(actionsLog);
        if (actionsLog.length > 0) {
            logInfo('All mungers failed, changes reversed.');
        }
        return;
    }

    logInfo('Mungers succeeded.');
}

/**
 * Undo previous actions
 * @param actionsLog Previous actions done
 */
function undoActions(actionsLog) {
    for (const action of actionsLog) {
        action['function'].apply(action['object'], action['arguments']);
    }
}

/**
 *
 * @param nodes
 * @param documentWidth
 * @param actionsLog
 * @returns
 */
function transformBlockElements(nodes, documentWidth, actionsLog) {
    let elementsAreModified = false;
    for (const node of nodes) {
        const widthString = node.style.width || node.style.minWidth;
        const index = widthString ? widthString.indexOf('px') : -1;
        if (index >= 0 && widthString.slice(0, index) > documentWidth) {
            saveStyleProperty(node, 'width', actionsLog);
            saveStyleProperty(node, 'minWidth', actionsLog);
            saveStyleProperty(node, 'maxWidth', actionsLog);

            node.style.width = '100%';
            node.style.minWidth = '';
            node.style.maxWidth = widthString;

            elementsAreModified = true;
        }
    }

    return elementsAreModified;
}

/**
 *
 * @param images
 * @param documentWidth
 * @param actionsLog
 * @returns
 */
function transformImages(images, documentWidth, actionsLog) {
    let imagesAreModified = false;
    for (const image of images) {
        if (image.offsetWidth > documentWidth) {
            saveStyleProperty(image, 'width', actionsLog);
            saveStyleProperty(image, 'maxWidth', actionsLog);
            saveStyleProperty(image, 'height', actionsLog);

            image.style.width = '100%';
            image.style.maxWidth = `${documentWidth}px`;
            image.style.height = 'auto';

            imagesAreModified = true;
        }
    }

    return imagesAreModified;
}

/**
 *
 * @param nodes
 * @param conditionFunction
 * @param classToAdd
 * @param actionsLog
 * @returns
 */
function addClassToElements(nodes, conditionFunction, classToAdd, actionsLog) {
    let classAdded = false;
    for (const node of nodes) {
        if (!conditionFunction || conditionFunction(node)) {
            if (node.classList.contains(classToAdd)) { continue; }
            node.classList.add(classToAdd);
            classAdded = true;
            actionsLog.push({ function: node.classList.remove, object: node.classList, arguments: [classToAdd] });
        }
    }
    return classAdded;
}

/**
 *
 * @param node
 * @param property
 * @param actionsLog
 */
function saveStyleProperty(node, property, actionsLog) {
    const savedName = `data-${property}`;
    node.setAttribute(savedName, node.style[property]);
    actionsLog.push({ function: undoSetProperty, object: node, arguments: [property, savedName] });
}

/**
 * Undo a previously changed property
 * @param property Property to undo
 * @param savedProperty Saved property
 */
function undoSetProperty(property, savedProperty) {
    this.style[property] = savedProperty ? this.getAttribute(savedProperty) : '';
}

/**
 * Checks if a table should be munged
 * @param table Table HTML object
 * @returns true if the object has a width as an attribute or in its style
 */
function shouldMungeTable(table) {
    return table.hasAttribute('width') || table.style.width;
}

// Logger

function logInfo(text) {
    console.info(`[MUNGER_LOG] ${text}`);
}

function logTransformation(action, element, elementWidth, newWidth, documentWidth) {
    logInfo(`Ran ${action} on element ${element.tagName} - oldWidth=${elementWidth}, newWidth=${newWidth}, docWidth=${documentWidth}`);
}
