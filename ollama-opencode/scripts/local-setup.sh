#!/bin/sh
set -eu

cd "$(dirname "$0")/.."
model='qwen2.5-coder:32b-instruct-q4_K_M'
local_model='qwen3-coder-local:32k'
endpoint='http://127.0.0.1:11434'
config='opencode.json'
template='scripts/opencode.local.json'

check_config() {
  for file in opencode.jsonc .opencode/opencode.json .opencode/opencode.jsonc; do
    if [ -e "$file" ]; then
      printf 'Conflicting project config: %s. Review it before continuing.\n' "$file" >&2
      exit 1
    fi
  done
  if [ -e "$config" ] && ! cmp -s "$template" "$config"; then
    printf 'Existing %s differs from the local configuration; it was not changed.\n' "$config" >&2
    exit 1
  fi
}

server_ready() {
  curl --noproxy '*' --silent --fail --max-time 2 "$endpoint/api/tags" >/dev/null
}

case "${1:-}" in
  setup)
    check_config
    command -v brew >/dev/null 2>&1 || { echo 'Homebrew is required. Install it first.' >&2; exit 1; }
    command -v ollama >/dev/null 2>&1 || brew install ollama
    command -v opencode >/dev/null 2>&1 || brew install opencode
    case "$(opencode --version)" in 2.*) ;; *) echo 'OpenCode 2.x is required for this configuration.' >&2; exit 1 ;; esac
    if ! server_ready; then
      mkdir -p "${XDG_STATE_HOME:-$HOME/.local/state}/chatgpt-access"
      log="${XDG_STATE_HOME:-$HOME/.local/state}/chatgpt-access/ollama.log"
      OLLAMA_HOST=127.0.0.1:11434 OLLAMA_NO_CLOUD=1 nohup ollama serve >>"$log" 2>&1 </dev/null &
      tries=0
      until server_ready; do
        tries=$((tries + 1))
        if [ "$tries" -ge 30 ]; then
          printf 'Ollama did not start. Check %s\n' "$log" >&2
          exit 1
        fi
        sleep 1
      done
    else
      echo 'Using the existing Ollama endpoint. Check its network binding and cloud settings independently.'
    fi
    if ! OLLAMA_HOST=127.0.0.1:11434 ollama show "$model" >/dev/null 2>&1; then
      OLLAMA_HOST=127.0.0.1:11434 ollama pull "$model"
    fi
    modelfile=$(mktemp "${TMPDIR:-/tmp}/ollama-modelfile.XXXXXX")
    trap 'rm -f "$modelfile"' EXIT HUP INT TERM
    printf 'FROM %s\nPARAMETER num_ctx 32768\n' "$model" > "$modelfile"
    if OLLAMA_HOST=127.0.0.1:11434 ollama show "$local_model" >/dev/null 2>&1; then
      echo "The model $local_model already exists; leaving it unchanged."
    else
      OLLAMA_HOST=127.0.0.1:11434 ollama create "$local_model" -f "$modelfile"
    fi
    if [ ! -e "$config" ]; then
      (umask 077; set -C; cat "$template" > "$config")
    fi
    echo 'Setup complete. Run task verify before starting OpenCode.'
    ;;
  verify)
    check_config
    [ -f "$config" ] || { echo 'Project configuration is missing; run task setup.' >&2; exit 1; }
    command -v ollama >/dev/null 2>&1 || { echo 'Ollama is missing.' >&2; exit 1; }
    command -v opencode >/dev/null 2>&1 || { echo 'OpenCode is missing.' >&2; exit 1; }
    server_ready || { echo 'Ollama is not responding at 127.0.0.1:11434.' >&2; exit 1; }
    OLLAMA_HOST=127.0.0.1:11434 ollama show "$local_model" --modelfile | grep -Eq '^PARAMETER[[:space:]]+num_ctx[[:space:]]+32768([[:space:]]|$)' || {
      echo 'The local model is missing or does not have the expected 32K context.' >&2; exit 1;
    }
    echo 'Local tools, endpoint, model context, and project configuration verified.'
    echo 'Review global, managed, and agent settings: they may override project settings.'
    ;;
  *) echo 'Usage: sh scripts/local-setup.sh {setup|verify}' >&2; exit 2 ;;
esac
