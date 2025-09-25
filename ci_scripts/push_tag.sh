#!/bin/sh
set -e

# CI_ARCHIVE_PATH - The path to the signed app in the Xcode Cloud runner.
# CI_BUILD_NUMBER - The build number assigned by Xcode Cloud.
# CI_PRIMARY_REPOSITORY_PATH - The location of the source code in the Xcode Cloud runner.
# CI_PRODUCT - The name of the product being built.
#
# GIT_EMAIL - The email address associated with the Xcode Cloud bot user.
# GIT_GPG_KEY_PASSPHRASE - The passphrase for the GPG private key.
#
# GITHUB_REPOSITORY_OWNER - The owner of the GitHub repository.
# GITHUB_REPOSITORY_NAME - The name of the GitHub repository.
# GITHUB_TOKEN - A GitHub token with permissions to create releases.
#
# KCHAT_PRODUCT_ICON - The icon to use for the product in the kChat message.
# KCHAT_WEBHOOK_URL - The webhook URL for the kChat channel.

brew install gnupg

# MARK: - Import GPG Key and Deduce Key ID

echo "$GIT_GPG_KEY_PASSPHRASE" | openssl enc -aes-256-cbc -d -in ci_scripts/gpg-key.txt.encrypted -pass stdin | gpg --batch --import

# Tell gpg-agent to allow loopback pinentry
echo "allow-loopback-pinentry" >> ~/.gnupg/gpg.conf
echo "pinentry-mode loopback" >> ~/.gnupg/gpg.conf
export GPG_TTY=$(tty)

# Get key ID of the imported private key (first one found)
GIT_GPG_KEY_ID=$(gpg --list-secret-keys --with-colons | awk -F: '/^sec:/ {print $5; exit}')

if [ -z "$GIT_GPG_KEY_ID" ]; then
    echo "⚠️ Error: Failed to import GPG private key or detect key ID."
    exit 1
fi

# MARK: - Push Git Tag

# Navigate to the repository
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Get version from the built app
VERSION=$(xcodebuild -showBuildSettings | grep MARKETING_VERSION | awk '{print $3}')

# Ensure VERSION is not empty
if [ -z "$VERSION" ]; then
    echo "⚠️ Error while retrieving version from Info.plist"
    exit 1
fi

TAG_NAME="Beta-$VERSION-b$CI_BUILD_NUMBER"

# Configure git
git config user.name "Xcode Cloud"
git config user.email "$GIT_EMAIL"
git config user.signingkey "$GIT_GPG_KEY_ID"
git config tag.gpgSign true

git remote set-url origin https://$GITHUB_TOKEN@github.com/$GITHUB_REPOSITORY_OWNER/$GITHUB_REPOSITORY_NAME.git

# Check if tag already exists then create it and push it
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "⚠️ Tag $TAG_NAME already exists, skipping..."
else
    git tag -s "$TAG_NAME" -m "Beta Release $TAG_NAME" \
        --local-user "$GIT_GPG_KEY_ID" \
        --sign --force \
        --command="gpg --batch --yes --pinentry-mode loopback --passphrase $GIT_GPG_KEY_PASSPHRASE"

    git push origin "$TAG_NAME"
fi

# MARK: - GitHub Release

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

GITHUB_API_URL="https://api.github.com/repos/$GITHUB_REPOSITORY_OWNER/$GITHUB_REPOSITORY_NAME/releases"
RESPONSE=$(curl -s -w "\n%{http_code}" \
    -X POST \
    -H "Authorization: Bearer $GITHUB_TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    -d "$RELEASE_PAYLOAD" \
    "$GITHUB_API_URL")

# Check GitHub response
HTTP_STATUS=$(echo "$RESPONSE" | tail -n1)
if [ "$HTTP_STATUS" -ne 201 ]; then
    echo "⚠️ Error while pushing GitHub release: $HTTP_STATUS"
    exit 1
fi

HTTP_BODY=$(echo "$RESPONSE" | sed '$d')
RELEASE_URL=$(echo "$HTTP_BODY" | tr -d '\000-\037' | jq -r '.html_url')

# MARK: - kChat Notification

AAPL_LOGO=$(((RANDOM % 120) + 1))
TESTFLIGHT_RELEASE_NOTE=$(cat "$CI_PRIMARY_REPOSITORY_PATH/TestFlight/WhatToTest.en-GB.txt")

MESSAGE=$(cat <<EOF
#### :aapl-$AAPL_LOGO::$KCHAT_PRODUCT_ICON: $CI_PRODUCT
##### :testflight: Version $VERSION-b$CI_BUILD_NUMBER available on TestFlight

$TESTFLIGHT_RELEASE_NOTE


:github:  [See changelog]($RELEASE_URL)
EOF
)

MESSAGE_JSON=$(printf '%s' "$MESSAGE" | jq -Rs '{text: .}')
curl -i -X POST \
    -H 'Content-Type: application/json' \
    -d "$MESSAGE_JSON" \
    "$KCHAT_WEBHOOK_URL"
