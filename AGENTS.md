# AGENTS.md

## Purpose
- This repository bootstraps a Linux developer machine, with emphasis on Neovim setup.
- The codebase is mostly Bash scripts and Neovim Lua config (no package manager project layout).
- Treat this file as operational guidance for coding agents working in this repo.

## Repository Map
- `install_things.sh`: main installer flow (Neovim download/install + config linking).
- `install_dependencies.sh`: installs external CLI dependencies (currently opencode CLI).
- `install_pi.sh`: installs Pi and clones/updates the pi-config-sync repo at `~/.pi/agent` (no credentials for a public repo, token for a private one); Pi installs the packages declared in its settings.json on first run.
- `remove_pi.sh`: teardown for Pi config and installs (the synced config remains on the remote).
- `remove_things.sh`: teardown for Neovim config/data.
- `Dockerfile` / `.dockerignore`: reusable image that ships the pinned Neovim + Pi environment plus a `/linux-quick-setup` git checkout for in-container editing.
- `docker/entrypoint.sh`: container entrypoint; pull-only config refresh (fast-forward, else reset to the remote) then exec.
- `docker/setup-git-auth.sh`: in-container helper that stores GitHub HTTPS credentials (`~/.git-credentials`) and the commit identity so pushes from `/linux-quick-setup` work.
- `docker-compose.yaml`: brings up the image with the code mounted at `/workspace` and Pi state in named volumes.
- `run_container.sh`: launcher for the Compose service; starts it detached (`docker compose up -d`, `BUILD=1` adds `--build`) and opens a shell with `docker compose exec dev`, so the container survives a lost connection and `Ctrl+P` reaches the container (exec bypasses docker's detach-key proxy).
- `.github/workflows/build-image.yml`: manual workflow that builds and publishes the image to GHCR.
- `docs/plans/**`: implementation plans and progress logs.
- `utils.sh`: shared Bash helpers (array/string/file helpers, logging, parsing).
- `back_bone.sh`: terminal, color, menu, prompt, and print/log framework.
- `neovim/init.lua`: Neovim entrypoint.
- `neovim/lua/gly_custom/**`: custom Neovim modules and plugin specs.
- `tmux/.tmux.conf`: tmux config, symlinked to `~/.tmux.conf` by `install_things.sh`; the tmux binary itself is installed by the `Dockerfile`.

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
- The Docker image targets glibc Debian-based images on `amd64` only (no Alpine/musl, no arm64); `debian:bookworm-slim` is the default and only built/verified variant, while `BASE_IMAGE` can re-base onto other glibc images (unverified).
- tmux is installed in the image only, from a pinned static build (`TMUX_VERSION`); the shipped `tmux/.tmux.conf` needs tmux 3.5+ (bookworm's apt tmux is 3.3a), and `install_things.sh` symlinks that config on hosts too.
- The image sets `LANG=C.UTF-8` (Compose pins the same value). tmux only treats a client as UTF-8 when `TMUX` is set or the locale contains `UTF-8`; with a non-UTF-8 locale it replaces rounded box corners and Nerd Font icons with `_`.
- Docker's CLI escape proxy holds a lone `Ctrl+P` (default detach sequence `ctrl-p,ctrl-q`) before it reaches the container, so `Ctrl+P` looks dead when the container's own stdio is attached (`docker compose up` without `-d`, `docker run -it`, `docker attach`) — Pi's `app.model.cycleForward`, readline history. `docker compose exec` (what `run_container.sh` uses) is not affected; for attached sessions set `detachKeys` in the docker CLI config or pass `--detach-keys='ctrl-^,ctrl-^'`.
- nvim-tree / nvim-web-devicons icons are Nerd Font Private Use Area glyphs, so the machine running the terminal needs **Hack Nerd Font** installed and selected; the image cannot supply fonts. An icon shown as `_` is the locale issue above, tofu boxes mean the font is missing.
- Pi extension versions are pinned in the config repo's `~/.pi/agent/settings.json`; the image seeds `~/.pi/agent/npm` from it read-only, and the container resets to the remote config when histories diverge.
- The image's non-root `dev` user has passwordless `sudo` (`/etc/sudoers.d/dev`) for runtime package installs; those are ephemeral, and the reproducible path is to rebuild the image.

## Build, Lint, and Test Commands

### Build / Run (project-equivalent)
- There is no compile/build pipeline.
- Use script execution as the build/run workflow:
  - Full setup: `bash install_things.sh`
  - Dependency setup only: `bash install_dependencies.sh`
  - Pi setup only: `bash install_pi.sh`
  - Teardown: `bash remove_things.sh`
  - Pi teardown: `bash remove_pi.sh`
  - Docker image build (the default config repo is public; no token needed):
    - `docker buildx build --build-arg PI_SYNC_REF=main -t linux-quick-setup:latest .`
  - Docker image run (mount the code repo at `/workspace`; add `-e GITHUB_TOKEN` only for a private config repo):
    - `docker run --rm -it -v "$PWD:/workspace" linux-quick-setup:latest`
  - Launcher (starts the Compose service detached, then `docker compose exec dev bash -l`, so the container survives a lost connection and `Ctrl+P` arrives intact):
    - `bash run_container.sh`
    - `bash run_container.sh nvim`
    - `BUILD=1 bash run_container.sh`
  - In-container repo for editing/pushing (nvim config symlinks point here):
    - `/linux-quick-setup` (git checkout; run `setup-git-auth` or set `GIT_USER_NAME`/`GIT_USER_EMAIL` and `GITHUB_TOKEN` to commit and push)
  - Docker Compose (build + interactive shell; add `-e GITHUB_TOKEN` only for a private config repo):
    - `docker compose up --build`
  - Docker Compose one-off command:
    - `docker compose run --rm dev nvim`
  - Publish the image (manual CI in GitHub Actions; no repository secrets):
    - GitHub → Actions → "Build and publish image" → Run workflow, or `gh workflow run build-image.yml -f tag=latest -f pi_sync_ref=main`
  - Pull the published image (public GHCR package; make it public once in the package settings):
    - `docker pull ghcr.io/glyochi/linux-quick-setup:latest`
  - Use the published image with Compose:
    - `docker compose pull && docker compose up --no-build`

### Lint / Static Checks
- Bash syntax check (all scripts):
  - `bash -n back_bone.sh utils.sh install_things.sh install_dependencies.sh install_pi.sh remove_pi.sh remove_things.sh run_container.sh docker/entrypoint.sh docker/setup-git-auth.sh`
- Bash syntax check (single script):
  - `bash -n utils.sh`
- ShellCheck (all scripts, when installed):
  - `shellcheck back_bone.sh utils.sh install_things.sh install_dependencies.sh install_pi.sh remove_pi.sh remove_things.sh run_container.sh docker/entrypoint.sh docker/setup-git-auth.sh`
- ShellCheck (single script):
  - `shellcheck install_things.sh`
- Lua parse smoke check (single file):
  - `nvim --headless '+lua dofile("neovim/lua/gly_custom/plugins/mason.lua")' +qa`
- Lua integration smoke check (entrypoint):
  - `nvim --headless '+lua dofile("neovim/init.lua")' +qa`
- Dockerfile static check:
  - `docker buildx build --check -f Dockerfile .`

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
- Docker changes:
  1. `docker buildx build --check -f Dockerfile .`
  2. `bash -n docker/entrypoint.sh`
  3. `docker buildx build -t linux-quick-setup:test .` then `docker run --rm linux-quick-setup:test nvim --version` and `docker run --rm linux-quick-setup:test tmux -V`.

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
- CI exists only to publish the Docker image (`.github/workflows/build-image.yml`, manual trigger); the Bash/Lua scripts have no CI.
- No standardized formatter config for Bash/Lua is present.
- No dedicated automated test suite exists yet.
