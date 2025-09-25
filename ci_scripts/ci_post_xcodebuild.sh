#!/bin/sh
set -e

#./check_preconditions.sh

cd ..

curl https://mise.run | sh
export PATH="$HOME/.local/bin:$PATH"

mise install
eval "$(mise activate bash --shims)"

# do not push to sentry for tets

ci_scripts/push_tag.sh
