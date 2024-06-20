#!/bin/bash
set -e

if [ "Release" = "${CONFIGURATION}" ]; then # Only do this for release builds
    
    # Path to the app directory
    APP_DIR_PATH="${BUILT_PRODUCTS_DIR}/${EXECUTABLE_FOLDER_PATH}"
    # Strip main binary
    strip -rSTx "${APP_DIR_PATH}/${EXECUTABLE_NAME}"
    # Path to the Frameworks directory
    APP_FRAMEWORKS_DIR="${APP_DIR_PATH}/Frameworks"
    
    # Strip symbols from frameworks, if Frameworks/ exists at all
    # ... as long as the framework is NOT signed by Apple
    if [ -d "${APP_FRAMEWORKS_DIR}" ]
    then
        find "${APP_FRAMEWORKS_DIR}" -type f -perm +111 -maxdepth 2 -mindepth 2 -exec bash -c 'codesign -v -R="anchor apple" "{}" &> /dev/null || (echo "{}" && strip -rSTx "{}")' \;
    fi
fi

# Source: https://docs.emergetools.com/docs/strip-binary-symbols
