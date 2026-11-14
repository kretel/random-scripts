# Local Qwen coding setup

Choose either workflow on macOS. Both use Homebrew, Ollama, and OpenCode 2.x. The Taskfile workflow uses `qwen2.5-coder:32b-instruct-q4_K_M` (~19 GB); the mise workflow uses whichever model is selected in `mise.toml` (currently `deepseek-r1:32b`). Install Homebrew and the runner you choose first; setup installs missing Ollama and OpenCode. Neither workflow pins software versions or model digests.

## Model Selection

To switch between different models, run:
```sh
mise run select-model
```

Select `0` to quit without changing the model. Select `11` for a 32K context (`32768`) or `12` for a 64K context (`65536`). When you switch, the task checks whether the model is already pulled and pulls it if it is missing.

You can also pass a model directly:
```sh
mise run select-model qwen3-coder-next:q4_K_M
```

Available models:
- `deepseek-r1:32b` — 20 GB, reasoning/thinking
- `qwen3-coder-next:q4_K_M` — 52 GB, agentic coding; tight on 64 GB
- `qwen3.8:27b-q8_0` — 27 GB, high-precision general/coding
- `qwen3.8-27B-GGUF:UD-Q5_K_M` — custom GGUF import, Q5_K_M
- `qwen3-coder:30b-a3b-q4_K_M` — 19 GB, fast agentic coding
- `qwen2.5-coder:32b-instruct-q4_K_M` — 20 GB, code generation/repair
- `glm-4.7-flash:q4_K_M` — 17 GB, fast general purpose
- `nemotron-3.5-lightning:30b-a3b-q4_K_M` — 25 GB, agent-focused MoE (menu default when pressing Enter)
- `llama3:70b-instruct-q4_K_M` — 43 GB, general purpose; tight on 64 GB
- `mixtral:8x7b-instruct-v0.1-q4_K_M` — 28 GB, MoE general purpose

## Taskfile

Install [Task](https://taskfile.dev/docs/installation), then from this directory run:

```sh
task setup
task verify
task smoke
opencode --standalone
```

Setup creates `opencode.json` only when no conflicting project configuration exists. It creates a local model alias with a 32K context and starts Ollama on loopback if needed. The server remains running after setup. If an existing server is reused, inspect its network binding and cloud settings yourself. `verify` checks configuration and model metadata; `smoke` sends real prompts through Ollama and OpenCode. Review the responses. OpenCode's broader configuration and saved approvals may override project settings; inspect those before using it.

## mise

Install [mise](https://mise.jdx.dev/getting-started), then from this directory run:

```sh
mise trust
mise run local setup
mise run local verify
mise run local
```

Each invocation starts a private Ollama server on `127.0.0.1:11435` and stops it afterward. Port 11435 must be free. OpenCode uses a temporary private profile and its sessions are discarded at exit. It runs in this directory; place the `mise.toml` in the project you want to work on. Verification sends a real prompt through OpenCode and displays Ollama's loaded model.

For either workflow, after launching OpenCode, ask it to read a small non-sensitive file and report its contents to check agent tool use. Ask it to make a disposable edit and confirm that it requests approval. Review responses and permissions before using it on important work. Local inference does not sandbox the agent or prevent approved shell commands, existing integrations, plugins, or broader system settings from using the network. Downloads require internet access.
