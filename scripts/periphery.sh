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
    detailedOutput=$(periphery scan --quiet)
else
    detailedOutput=$(periphery scan --quiet | sed "s|$(pwd)/||g")
fi

unusedCount=$(wc -l <<< "$detailedOutput" | tr -d '[:space:]')

echo "$detailedOutput"
echo "Total unused instances $unusedCount"
