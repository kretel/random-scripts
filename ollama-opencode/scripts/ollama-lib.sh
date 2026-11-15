# Sourced by mise tasks. Requires OLLAMA_HOST; ollama_start sets ollama_pid.

ollama_ready() {
  curl --noproxy '*' --max-time 1 --fail --silent \
    "http://$OLLAMA_HOST/api/version" >/dev/null 2>&1
}

# Usage: ollama_start <log-file>
ollama_start() {
  local log=$1 attempt
  ollama serve >"$log" 2>&1 &
  ollama_pid=$!
  for (( attempt=0; attempt<60; attempt++ )); do
    kill -0 "$ollama_pid" 2>/dev/null || break
    if ollama_ready; then
      return 0
    fi
    sleep 1
  done
  cat "$log" >&2
  printf 'Ollama did not start on %s.\n' "$OLLAMA_HOST" >&2
  return 1
}
