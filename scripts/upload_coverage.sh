#!/usr/bin/env bash
set -euo pipefail

# Convert xccov coverage to SonarCloud generic XML format
function convert_xccov_to_xml {
  sed -n \
    -e '/:$/s/&/\&amp;/g;s/^\(.*\):$/  <file path="\1">/p' \
    -e 's/^ *\([0-9][0-9]*\): 0.*$/    <lineToCover lineNumber="\1" covered="false"\/>/p' \
    -e 's/^ *\([0-9][0-9]*\): [1-9].*$/    <lineToCover lineNumber="\1" covered="true"\/>/p' \
    -e 's/^$/  <\/file>/p'
}

function xccov_to_generic {
  local xcresult="$1"
  echo '<coverage version="1">'
  xcrun xccov view --archive "$xcresult" | convert_xccov_to_xml
  echo '</coverage>'
}

function check_xcode_version() {
  local major=${1:-0} minor=${2:-0}
  [ "$major" -gt 13 ] || ([ "$major" -eq 13 ] && [ "$minor" -ge 3 ])
}

# --- MAIN ---
xcresult="ResultBundle.xcresult"
coverage_report="coverage.xml"

if [[ ! -d $xcresult ]]; then
  echo "Path not found: $xcresult" 1>&2
  exit 1
fi

xccov_to_generic "$xcresult" > "$coverage_report"

if ! command -v sonar-scanner &>/dev/null; then
  echo "sonar-scanner not found. Installing with Homebrew..."
  brew install sonar-scanner
fi

sonar-scanner \
  -Dsonar.projectKey=$SONAR_PROJECT_KEY \
  -Dsonar.organization=infomaniak \
  -Dsonar.host.url=https://sonarcloud.io \
  -Dsonar.login=$SONAR_TOKEN \
  -Dsonar.coverageReportPaths="$coverage_report"

echo "Coverage uploaded to SonarCloud."
