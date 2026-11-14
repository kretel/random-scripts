#!/usr/bin/env bash
set -euo pipefail

# Read one model tag per line from stdin, optionally followed by |description.
if [[ $# -ne 0 ]]; then
  printf 'Usage: bash %s < model-list\n' "$0" >&2
  exit 2
fi

models_dir=${OLLAMA_MODELS:-$HOME/.ollama/models}
total=0
missing=0
printf 'Local model manifests in %s:\n' "$models_dir"
while IFS='|' read -r model description; do
  [[ -n $model ]] || continue
  total=$((total + 1))

  name=$model
  tag=latest
  if [[ ${name##*/} == *:* ]]; then
    tag=${name##*:}
    name=${name%:*}
  fi
  case "$name" in
    */*/*) host=${name%%/*}; name=${name#*/} ;;
    */*) host=registry.ollama.ai ;;
    *) host=registry.ollama.ai; name=library/$name ;;
  esac
  legacy_host=$host
  v2_host=${host//:/%3A}
  case "$host" in
    registry.ollama.ai|ollama.com)
      legacy_host=registry.ollama.ai
      v2_host=ollama.com
      ;;
  esac

  if [[ -s "$models_dir/manifests/$legacy_host/$name/$tag" ||
        ( $v2_host == ollama.com && -s "$models_dir/manifests/ollama.com/$name/$tag" ) ||
        -s "$models_dir/manifests-v2/$v2_host/$name/$tag" ]]; then
    printf '✓ %s\n' "$model"
  else
    printf '✗ %s\n' "$model"
    missing=$((missing + 1))
  fi
done

printf '\n%d/%d manifests fetched; %d missing.\n' "$((total - missing))" "$total" "$missing"
