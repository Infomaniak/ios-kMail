#!/bin/bash

eval "$($HOME/.local/bin/mise activate bash --shims)"

tuist install
tuist generate --no-open


# Perform the periphery scan and handle directory removal based on argument
if [[ "$1" == "--full-dir" ]]; then
    detailedOutput=$(periphery scan --quiet --retain-codable-properties)
else
    detailedOutput=$(periphery scan --quiet --retain-codable-properties | sed "s|$(pwd)/||g")
fi

if [[ "$detailedOutput" == *"No unused code detected."* ]]; then
    unusedCount=0
else
    unusedCount=$(wc -l <<< "$detailedOutput" | tr -d '[:space:]')
fi

echo "$detailedOutput"
echo "Total unused instances $unusedCount"

# Output script result to GITHUB_OUTPUT to get it in next step
echo 'detailed_output<<EOF' >> $GITHUB_OUTPUT
echo "$detailedOutput" >> $GITHUB_OUTPUT
echo 'EOF' >> $GITHUB_OUTPUT

echo "unused_count=$unusedCount" >> $GITHUB_OUTPUT


if [[ "$1" == "--clean" ]]; then
    rm -R $HOME/Library/Caches/com.github.peripheryapp
fi
