#!/bin/sh
set -e

# CI_APP_STORE_SIGNED_APP_PATH - The path to the signed app in the Xcode Cloud runner.
# CI_BUILD_NUMBER - The build number assigned by Xcode Cloud.
# CI_PRIMARY_REPOSITORY_PATH - The location of the source code in the Xcode Cloud runner.
#
# GIT_EMAIL - The email address associated with the Xcode Cloud bot user.
# GIT_GPG_KEY - The GPG key ID used to sign the git tag.
# GITHUB_REPOSITORY_OWNER - The owner of the GitHub repository.
# GITHUB_REPOSITORY_NAME - The name of the GitHub repository.
# GITHUB_TOKEN - A GitHub token with permissions to create releases.

# Get version from the built app
VERSION=$(/usr/libexec/PlistBuddy -c "Print ApplicationProperties:CFBundleShortVersionString" "${CI_APP_STORE_SIGNED_APP_PATH}/Info.plist" 2>/dev/null || echo "")

# Ensure VERSION is not empty
if [[ -z "$VERSION" ]]; then
    echo "⚠️  Error while retrieving version from Info.plist"
    exit 1
fi

TAG_NAME="Beta-$VERSION-b$CI_BUILD_NUMBER"

# Navigate to the repository
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Configure git
git config user.name "Xcode Cloud"
git config user.email "$GIT_EMAIL"
git config user.signingkey "$GIT_GPG_KEY"
git config tag.gpgSign true

# Check if tag already exists then create it and push it
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "⚠️  Tag $TAG_NAME already exists, skipping..."
else
    git tag "$TAG_NAME"
    git push origin "$TAG_NAME"
fi

# Create GitHub release
RELEASE_PAYLOAD=$(cat <<EOF
{
  "tag_name": "$TAG_NAME",
  "name": "$TAG_NAME",
  "draft": false,
  "prerelease": false,
  "generate_release_notes": true
}
EOF
)

GITHUB_API_URL="https://api.github.com/repos/${GITHUB_REPOSITORY_OWNER}/${GITHUB_REPOSITORY_NAME}/releases"
RESPONSE=$(curl -s -X POST \
  -H "Authorization: Bearer $GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  -d "$RELEASE_PAYLOAD" \
  "$GITHUB_API_URL")

# Check GitHub response
HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
RESPONSE_BODY=$(echo "$RESPONSE" | sed '$d')

case "$HTTP_CODE" in
    201)
        RELEASE_URL=$(echo "$RESPONSE_BODY" | grep -o '"html_url":"[^"]*"' | cut -d'"' -f4)
        echo "Release URL: $RELEASE_URL"
        ;;
    *)
        echo "Failed to create GitHub release (HTTP $HTTP_CODE)"
        exit 1
        ;;
esac