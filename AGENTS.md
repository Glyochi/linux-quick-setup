# AGENTS.md

## Purpose
- This repository bootstraps a Linux developer machine, with emphasis on Neovim setup.
- The codebase is mostly Bash scripts and Neovim Lua config (no package manager project layout).
- Treat this file as operational guidance for coding agents working in this repo.

## Repository Map
- `install_things.sh`: main installer flow (Neovim download/install + config linking).
- `install_dependencies.sh`: installs external CLI dependencies (currently opencode CLI).
- `remove_things.sh`: teardown for Neovim config/data.
- `utils.sh`: shared Bash helpers (array/string/file helpers, logging, parsing).
- `back_bone.sh`: terminal, color, menu, prompt, and print/log framework.
- `neovim/init.lua`: Neovim entrypoint.
- `neovim/lua/gly_custom/**`: custom Neovim modules and plugin specs.

## Rule Files (Cursor/Copilot)
- Checked paths:
  - `.cursor/rules/`
  - `.cursorrules`
  - `.github/copilot-instructions.md`
- Current status: none of these files exist in this repository.
- If they are added later, treat them as higher-priority local policy than this file.

## Environment Assumptions
- OS target: Linux.
- Shell target: Bash.
- Main Neovim version target in installer: `v0.11.1`.
- Scripts may depend on tools like `sudo`, `wget`, `tar`, `tree`, `tput`, and `curl`.

## Build, Lint, and Test Commands

### Build / Run (project-equivalent)
- There is no compile/build pipeline.
- Use script execution as the build/run workflow:
  - Full setup: `bash install_things.sh`
  - Dependency setup only: `bash install_dependencies.sh`
  - Teardown: `bash remove_things.sh`

### Lint / Static Checks
- Bash syntax check (all top-level scripts):
  - `bash -n back_bone.sh utils.sh install_things.sh install_dependencies.sh remove_things.sh`
- Bash syntax check (single script):
  - `bash -n utils.sh`
- ShellCheck (all top-level scripts, when installed):
  - `shellcheck back_bone.sh utils.sh install_things.sh install_dependencies.sh remove_things.sh`
- ShellCheck (single script):
  - `shellcheck install_things.sh`
- Lua parse smoke check (single file):
  - `nvim --headless '+lua dofile("neovim/lua/gly_custom/plugins/mason.lua")' +qa`
- Lua integration smoke check (entrypoint):
  - `nvim --headless '+lua dofile("neovim/init.lua")' +qa`

### Test Status
- There is no formal automated unit/integration test suite currently.
- Minimum verification bar is syntax/lint checks plus targeted runtime/script checks.

### Running a Single Test (important for agents)
- Since no test runner exists, treat a "single test" as one focused validation:
  - One Bash file syntax check: `bash -n <file>.sh`
  - One Bash file lint check: `shellcheck <file>.sh`
  - One Lua module load check: `nvim --headless '+lua dofile("<path>.lua")' +qa`
  - One behavior check by running only the changed script.
- Examples:
  - `bash -n install_things.sh`
  - `shellcheck utils.sh`
  - `nvim --headless '+lua dofile("neovim/lua/gly_custom/remap.lua")' +qa`

## Verification Workflow for Agents
- Bash-only changes:
  1. Run `bash -n` on touched Bash files.
  2. Run `shellcheck` on touched Bash files if available.
  3. Execute the smallest relevant script path for runtime confidence.
- Lua-only changes:
  1. Run headless `dofile` on each touched Lua file.
  2. Run headless `dofile("neovim/init.lua")` integration smoke check.
- Mixed Bash + Lua changes: run both workflows.

## Bash Style Guidelines

### Shebang, safety, and sourcing
- Use `#!/usr/bin/env bash` for executable Bash scripts.
- Use `set -Eeuo pipefail` in executable scripts (match existing pattern).
- Source shared helpers near file top (`. utils.sh` or `. back_bone.sh`).
- Keep sourcing order deterministic when there are dependencies between helpers.

### Imports / file organization
- Keep script-level constants near top (for example `CURRENT_DIR`, `TMP_DIR`).
- Group related logic blocks and leave blank lines between top-level functions.
- Avoid broad file reorganization unless explicitly requested.

### Formatting and structure
- Follow existing indentation style in touched files (tab-heavy in current scripts).
- Keep function declaration style consistent within a file (`name(){}` vs `name() {}`).
- Avoid unrelated reformatting and whitespace churn.

### Quoting and expansions
- Quote variable expansions by default (`"$var"`, `"${array[@]}"`).
- Use braces in mixed strings (`"${HOME}/.config"`).
- Leave expansions unquoted only when intentional word-splitting is required.

### Arrays and return conventions
- This repo uses global return slots: `RETURN_0`, `RETURN_1`, etc.
- When adding helper functions, clear return slots first when needed.
- Return arrays using `RETURN_0=("${arr[@]}")` to match repository conventions.
- Preserve and restore `IFS` in parsing helpers that modify it.

### Naming conventions
- Functions and local variables: `snake_case`.
- Constants/environment-like values: uppercase (`TMP_DIR`, `TARGET_NEOVIM_VERSION`).
- Prefer descriptive names over abbreviations except short loop indices.

### Error handling and command execution
- For hard failures, use `print_error`/`log_error` with actionable context, then `exit 1`.
- Check external command failures and provide clear remediation hints.
- Prefer idempotent operations (`mkdir -p`, safe relinking).
- Be explicit and careful around destructive operations (`rm -r`, `sudo rm -fr`).

## Lua / Neovim Style Guidelines

### Module layout and imports
- Keep `neovim/init.lua` small and focused on requiring local modules.
- Plugin specs should live in `neovim/lua/gly_custom/plugins/*.lua` and return tables.
- Use `local x = require("...")` for reused modules; inline `require` for one-off usage.
- Use `pcall(require, ...)` when dependency absence is acceptable.

### Formatting and readability
- Keep Lua tables and option blocks consistently formatted and easy to scan.
- Preserve existing style in touched files; avoid broad rewrites.
- Keep comments short and only when they clarify non-obvious behavior.

### Types, diagnostics, and naming
- Lua here is dynamically typed; type annotations are optional.
- Use EmmyLua annotations only when they materially improve diagnostics.
- Respect `.luarc.json` expectations (LuaJIT runtime and global `vim`).
- Use `snake_case` for local variables/functions unless API conventions dictate otherwise.

### Lua error handling
- Startup-critical paths should fail clearly with visible messaging.
- Optional features should degrade gracefully without breaking startup.

## Agent Change-Scope and Safety Rules
- Keep changes minimal and tightly scoped to the request.
- Do not rename files or do broad refactors without explicit instruction.
- Do not remove user-authored comments unless they are wrong or obsolete.
- Never commit secrets, tokens, machine-specific credentials, or local paths.

## Documentation Maintenance Rules
- If you add or change run/lint/test commands, update this file in the same change.
- If a real test framework is introduced (for example Bats), document:
  - full test command,
  - exact single-test command,
  - test directory conventions,
  - expected CI command/entrypoint.

## Known Gaps
- No CI pipeline is configured at the time of writing.
- No standardized formatter config for Bash/Lua is present.
- No dedicated automated test suite exists yet.
