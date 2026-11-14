#!/bin/bash
set -euo pipefail

# Switch the model in mise.toml and pull it if it is not already available.
# Usage: ./model-switcher.sh [model-name]

cd "$(dirname "$0")/.."
exec mise run select-model "$@"
