#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# --- Check Environment Variables ---
REQUIRED_VARS=(
  "WORKSPACE"
  "SCHEME"
  "API_ISSUER_ID"
  "API_KEY_ID"
  "SENTRY_URL"
  "SENTRY_ORG"
  "SENTRY_PROJECT"
  "SENTRY_AUTH_TOKEN"
)

for VAR in "${REQUIRED_VARS[@]}"; do
  if [[ -z "${!VAR}" ]]; then
    echo "Error: Environment variable $VAR is not set."
    exit 1
  fi
done

# --- Configuration ---
EXPORT_OPTIONS_PLIST="./scripts/ExportOptions.plist"
ARCHIVE_PATH="./build/$SCHEME.xcarchive"
IPA_PATH="./build/export"
CONSTANTS_FILE="./Tuist/ProjectDescriptionHelpers/Constants.swift"

# --- Arguments ---
if [[ $# -ne 1 ]]; then
  echo "Usage: $0 Beta-<Version>-b<Build>"
  echo "Example: $0 Beta-1.2.7-b10"
  exit 1
fi

INPUT_STRING=$1

# Extract Version and Build Number
if [[ $INPUT_STRING =~ Beta-([0-9]+\.[0-9]+\.[0-9]+)-b([0-9]+) ]]; then
  VERSION="${BASH_REMATCH[1]}"
  BUILD_NUMBER="${BASH_REMATCH[2]}"
else
  echo "Error: Input string must follow the format Beta-<Version>-b<Build> (e.g., Beta-1.2.7-b10)"
  exit 1
fi

# --- Clean previous build ---
echo "Cleaning previous build artifacts..."
rm -rf ./build
mkdir -p ./build

# --- Update Constants.swift ---
echo "Updating version and build number in $CONSTANTS_FILE..."
sed -i '' -e "s/\.marketingVersion(\"[^\"]*\")/.marketingVersion(\"$VERSION\")/" \
          -e "s/\.currentProjectVersion(\"[^\"]*\")/.currentProjectVersion(\"$BUILD_NUMBER\")/" "$CONSTANTS_FILE"

# --- Generate Xcode project using tuist ---
tuist install && tuist generate -n

# --- Clean Derived data ---
echo "Cleaning Derived data..."
xcodebuild -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    clean

# --- Create and export archive ---
echo "Archiving the app..."
xcodebuild -workspace "$WORKSPACE" \
    -scheme "$SCHEME" \
    -sdk iphoneos \
    -configuration Release \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates \
    -authenticationKeyPath "$PWD/private_keys/AuthKey_$API_KEY_ID.p8" \
    -authenticationKeyID "$API_KEY_ID" \
    -authenticationKeyIssuerID "$API_ISSUER_ID" \
    archive

echo "Exporting IPA..."
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportPath "$IPA_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS_PLIST"

# --- Upload IPA ---
echo "Uploading IPA to App Store Connect..."
xcrun altool --upload-app \
    --type ios \
    --file "$IPA_PATH/$SCHEME.ipa" \
    --apiKey "$API_KEY_ID" \
    --apiIssuer "$API_ISSUER_ID"

if [ $? -eq 0 ]; then
    echo "Upload successful!"
else
    echo "Upload failed. Check the logs above for details."
    exit 1
fi

# --- Upload symbols to Sentry ---
echo "Checking if sentry-cli is installed..."
if ! command -v sentry-cli &> /dev/null; then
  echo "sentry-cli not found. Installing with brew..."
  brew install sentry-cli
else
  echo "sentry-cli is already installed."
fi

  echo "Uploading symbols to Sentry"
sentry-cli upload-dif --url $SENTRY_URL \
    --org $SENTRY_ORG \
    --project $SENTRY_PROJECT \
    --auth-token $SENTRY_AUTH_TOKEN \
    --derived-data \
    --include-sources ~/Library/Developer/Xcode/DerivedData
