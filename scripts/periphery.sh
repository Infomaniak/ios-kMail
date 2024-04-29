#!/bin/bash

eval "$($HOME/.local/bin/mise activate -C $SRCROOT bash --shims)"

tuist install
tuist generate -n


# Check if the "--full-dir" argument is provided
if [[ "$1" == "--full-dir" ]]; then
    full_dir=true
else
    full_dir=false
fi

# Perform the periphery scan and handle directory removal based on argument
if "$full_dir"; then
    detailedOutput=$(periphery scan --quiet --enable-unused-import-analysis)
else
    detailedOutput=$(periphery scan --quiet --enable-unused-import-analysis | sed "s|$(pwd)/||g")
fi

unusedCount=$(wc -l <<< "$detailedOutput" | tr -d '[:space:]')

echo "$detailedOutput"
echo "Total unused instances $unusedCount"

# Output script result to GITHUB_OUTPUT to get it in next step
echo 'detailed_output<<EOF' >> $GITHUB_OUTPUT
echo "$detailedOutput" >> $GITHUB_OUTPUT
echo 'EOF' >> $GITHUB_OUTPUT

echo "unused_count=$unusedCount" >> $GITHUB_OUTPUT
