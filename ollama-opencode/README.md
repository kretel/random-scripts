# Local Qwen coding setup

Choose either workflow on macOS. Both use Homebrew, Ollama, and OpenCode 2.x. The Taskfile workflow uses `qwen2.5-coder:32b-instruct-q4_K_M` (~19 GB); the mise workflow defaults to `deepseek-r1:32b`. Install Homebrew and the runner you choose first; setup installs missing Ollama and OpenCode. Neither workflow pins software versions or model digests.

## Model Selection

To switch between different models, run:
```sh
mise run select-model
```

Select `0` to quit. The 32K and 64K context options appear after the last model. Press Enter to select the model configured as `menu_default_model`. When you switch, the task checks whether the model is already pulled and pulls it if it is missing.

The selector saves your model and context choices in the Git-ignored `.env` next to `mise.toml`. The next `mise run opencode` uses those choices. Remove either setting from `.env` to use its default from `mise.toml`.

You can also pass a model directly:
```sh
mise run select-model qwen3-coder-next:q4_K_M
```

To customize the menu, edit `models` in [mise.toml](mise.toml). Use one `tag|description` line per model.

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
mise run opencode setup
mise run opencode verify
mise run opencode
```

The `opencode` task runs `pre-check` first. You can also run `mise run pre-check` on its own to check that Ollama and OpenCode 2.x are installed and that the server port is free.

Each `opencode` invocation starts a private Ollama server on `127.0.0.1:11435` and stops it afterward. OpenCode uses a temporary private profile and its sessions are discarded at exit. It runs in this directory; place the `mise.toml` in the project you want to work on. Verification sends a real prompt through OpenCode and displays Ollama's loaded model.

For either workflow, after launching OpenCode, ask it to read a small non-sensitive file and report its contents to check agent tool use. Ask it to make a disposable edit and confirm that it requests approval. Review responses and permissions before using it on important work. Local inference does not sandbox the agent or prevent approved shell commands, existing integrations, plugins, or broader system settings from using the network. Downloads require internet access.
