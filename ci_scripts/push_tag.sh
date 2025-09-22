#!/bin/sh
set -e

# CI_APP_STORE_SIGNED_APP_PATH - The path to the signed app in the Xcode Cloud runner.
# CI_BUILD_NUMBER - The build number assigned by Xcode Cloud.
# CI_PRIMARY_REPOSITORY_PATH - The location of the source code in the Xcode Cloud runner.
# XCODE_CLOUD_GIT_EMAIL - The email address associated with the Xcode Cloud bot user.

# Get version from the built app
VERSION=$(/usr/libexec/PlistBuddy -c "Print ApplicationProperties:CFBundleShortVersionString" "${CI_APP_STORE_SIGNED_APP_PATH}/Info.plist" 2>/dev/null || echo "")

# Unsure VERSION is not empty
if [[ -z "$VERSION" ]]; then
    echo "⚠️  Error while retrieving version from Info.plist"
    exit 1
fi

TAG_NAME="Beta-${VERSION}-${CI_BUILD_NUMBER}"

# Navigate to the repository
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Configure git
git config user.name "Xcode Cloud"
git config user.email "$XCODE_CLOUD_GIT_EMAIL"

# Check if tag already exists then create it and push it
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "⚠️  Tag $TAG_NAME already exists, skipping..."
else
    git tag "$TAG_NAME"
    git push origin "$TAG_NAME"
fi

# Create GitHub release + post message ?
