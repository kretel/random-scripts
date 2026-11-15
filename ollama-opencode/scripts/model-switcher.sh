#!/bin/bash
set -euo pipefail

# Select a model, pull it if needed, and save the choice in the local .env.
# Usage: ./model-switcher.sh [model-name]

cd "$(dirname "$0")/.."
exec mise run select-model "$@"
