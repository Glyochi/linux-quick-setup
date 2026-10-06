# Purpose
This repo is for quickly setting up a new linux machine for development

# Todo
- add auto install neovim 0.10
- add auto install a few language servers inside install_things (lua-ls, vim-ls/which requires npm)

# Neovim
Includes:
- neovim 0.10
- lazy.nvim (package manager)
- some 
- treesitter (language parsers, help with hightlighting)
- telescope (fuzzyfinder for searching among files)
- fugitive (for git)
- lsp (language server provider, help with linking ls to vim)
- mason (language server manager)
- nvim-tree (For files structure)
- some other custom plugins/remaps for gly

Helpful commands
- :Lazy
- :LspInstall
- :Mason

# Selected lsp
- python: basedpyright (for type checking) + none-ls (for formatting, have to install black + pyproject.toml)

# Pi
Pi is the AI coding agent, installed and configured by `install_pi.sh`.
Personal Pi configuration (settings, skills, extensions, prompts, themes) is
synced across machines with the [`pi-config-sync`](https://www.npmjs.com/package/pi-config-sync)
package, which keeps the Pi agent directory (`~/.pi/agent`) itself as a git
repository.

- Install / refresh: `bash install_pi.sh`
- Teardown: `bash remove_pi.sh`
- Config repo: `https://github.com/Glyochi/pi-config-sync.git`
- Agent directory (the repo checkout): `~/.pi/agent`
- Fresh machine: `bash install_pi.sh` (prompts for a token only if the repo is private)

On a new machine the script clones the config repo into `~/.pi/agent` and
installs `npm:pi-config-sync`. A publicly readable repo needs no credentials; a
private one prompts for a GitHub token with the `repo` scope (or reads
`GITHUB_TOKEN`) and stores it in `~/.git-credentials`. After that, syncing is
automatic (about every 5 minutes and on shutdown); use `/gitsync status`,
`/gitsync sync`, `/gitsync pull`, or `/gitsync push` inside pi when you want to
force it.

Skills live in `~/.pi/agent/skills/` and load in every project.

# tmux

The Docker image ships tmux preconfigured from `tmux/.tmux.conf`, which
`install_things.sh` symlinks to `~/.tmux.conf` — the same pattern as the Neovim
config, so in-container edits are live and tracked by git. tmux is installed in
the image only; hosts keep their own.

The config needs **tmux 3.5 or newer** and sets:

- `extended-keys on` with `extended-keys-format csi-u`, so TUI apps such as `pi`
  can tell `Shift+Enter`, `Ctrl+Enter` and `Enter` apart.
- `extkeys` in `terminal-features` for `xterm*`, `screen*` and `tmux*`, so
  modified keys survive nesting inside another tmux.
- `set-clipboard on`, which copies through OSC 52 — no X11 or clipboard daemon is
  needed in the container.

Notes:

- The `xterm*`/`screen*`/`tmux*` patterns match the container tmux client's `TERM`.
  If the container is started from inside a **host** tmux, that host tmux must also
  enable extended keys (`set -s extended-keys on` on tmux 3.5+) or modified keys
  never reach the container.
- `set-clipboard on` uses OSC 52, so the outermost terminal must honor it (an outer
  host tmux also needs `set -g set-clipboard on`).
- On a bookworm host the symlinked config is newer than the distro tmux (3.3a),
  which rejects `extkeys`; install tmux from `bookworm-backports` (3.5a) or remove
  `~/.tmux.conf`. The symlink is inert when tmux is not installed.
- The image installs the pinned static build (`TMUX_VERSION` in the table below)
  because Debian bookworm's tmux 3.3a predates both options.

# Docker

Build a reusable image that ships the pinned Neovim + config, pinned Pi, the
pinned Pi package tree, and the `pi-config-sync` config repo baked at a pinned
ref. The linux-quick-setup repo is also cloned into `/linux-quick-setup` so you
can edit (for example) the Neovim config inside the container and push it. Mount
the code you want to work on at `/workspace`.

```bash
docker build --build-arg PI_SYNC_REF=<tag-or-sha> -t linux-quick-setup:latest .
```

The default config repo is public, so no token is needed. For a private
`PI_SYNC_REPO`, add `--secret id=github_token,env=GITHUB_TOKEN`.

Run it. The entrypoint fast-forwards the baked config to `origin/main` (the
public repo needs no token) and never pushes:

```bash
docker run --rm -it \
  -v "$PWD:/workspace" \
  linux-quick-setup:latest
```

Use `nvim`, `pi`, and `tmux` inside the container. Add `-e GITHUB_TOKEN` only for a
private repo, or set `PI_SYNC_REHYDRATE=0` to skip the fetch.

The container has no git identity, and pi-config-sync's automatic sync commits
need one. Set `GIT_USER_NAME`/`GIT_USER_EMAIL` (the entrypoint applies them at
startup) or run `setup-git-auth` before starting pi, otherwise the sync fails
with `Author identity unknown`.

## Editing linux-quick-setup in the container

The image ships a real git checkout of this repo at `/linux-quick-setup` with an
`origin` remote. `~/.config/nvim` symlinks into `/linux-quick-setup/neovim`, so
edits there take effect immediately in Neovim and show up in `git status`.
`vim` and `vi` are aliased to `nvim` in the login profile and `~/.bashrc`.
`~/.tmux.conf` symlinks into `/linux-quick-setup/tmux/.tmux.conf` the same way;
restart the tmux server (`tmux kill-server`) for config changes to take effect.

To commit and push from inside the container, provide the token (for auth) and
an identity:

```bash
docker compose run --rm -it \
  -e GITHUB_TOKEN -e GIT_USER_NAME="You" -e GIT_USER_EMAIL=you@example.com dev bash -l
# inside the container:
git -C /linux-quick-setup checkout -b my-change
$EDITOR /linux-quick-setup/neovim/init.lua
git -C /linux-quick-setup add -A
git -C /linux-quick-setup commit -m "tweak neovim"
git -C /linux-quick-setup push -u origin my-change
```

Instead of passing the credentials through the environment, run the bundled
helper inside the container:

```bash
setup-git-auth            # prompts for the GitHub username and token (hidden)
setup-git-auth --check    # also verifies the token against the GitHub API
```

It writes `~/.git-credentials` (mode 600) via the git `store` helper and sets the
global commit identity, so `git push` works and pi-config-sync's automatic
`git commit` has an author. Without `--name`/`--email` it keeps an existing
identity or falls back to GitHub's noreply address
(`<user>@users.noreply.github.com`).

`LQS_REF` (build arg) controls the ref the image clones and defaults to `main`.
Build with `LQS_REF=$(git rev-parse HEAD)` (or your branch) so the baked checkout
matches your tree instead of `main`.

## Published image (CI)

A manual GitHub Actions workflow (`.github/workflows/build-image.yml`) builds
the image and pushes it to GitHub Container Registry. Trigger it from
**Actions → Build and publish image → Run workflow**, choosing the image `tag`
(default `latest`) and the `pi_sync_ref` to bake (default `main`). The workflow
must exist on the default branch (`main`) for that button to appear. Each run
publishes two tags:

- `ghcr.io/glyochi/linux-quick-setup:<tag>`
- `ghcr.io/glyochi/linux-quick-setup:sha-<short-sha>`

The job is manual-only and uses the built-in `GITHUB_TOKEN` (no repository
secrets). It smoke-tests the published image with `nvim --version` and
`pi --version`.

GHCR packages start private even for a public repo, so make it public once:
**Packages → linux-quick-setup → Package settings → Change visibility → Public**.

```bash
docker pull ghcr.io/glyochi/linux-quick-setup:latest
docker run --rm -it -v "$PWD:/workspace" ghcr.io/glyochi/linux-quick-setup:latest
```

With Compose, pull the published image instead of building locally:

```bash
docker compose pull && docker compose up --no-build
```

The published image is built with `DEV_UID`/`DEV_GID` 1000; if your host uid
differs, build locally or override the user at run time.

## Docker Compose

`docker-compose.yaml` wraps the same image, mounting the code at `/workspace`
and keeping Pi sessions and machine state in named volumes:

```bash
docker compose up --build
# one-off:
docker compose run --rm dev nvim
```

Override `CODE_DIR`, `BASE_IMAGE`, `IMAGE_TAG`, `TMUX_VERSION`, `PI_SYNC_REF`,
`DEV_UID`/`DEV_GID`, or `PI_SYNC_REHYDRATE` through the environment or a `.env`
file. The Pi login persists in the `pi-auth` volume, so `pi` stays signed in
across runs — run `/login` once. To reuse an existing host login instead, follow
the commented volume in `docker-compose.yaml`.

## Stacking on another base

The image builds inside whatever glibc base you pass (`debian:bookworm-slim` by
default), so it can be layered onto a specialized image:

```bash
docker build --build-arg BASE_IMAGE=python:3.12-slim -t my-specialized-env .
```

Non-default bases (for example a CUDA/ML image) work the same way but are not
verified by this repo.

## Pinned versions

Override any pin with `--build-arg`:

| Build arg | Default | Purpose |
| --- | --- | --- |
| `BASE_IMAGE` | `debian:bookworm-slim` | Base image to build on (Debian by default) |
| `NEOVIM_VERSION` | `v0.11.1` | Neovim release |
| `TMUX_VERSION` | `3.7c` | tmux static build from `tmux-builds` (image only) |
| `NODE_VERSION` | `22.23.3` | Node.js (official tarball) |
| `PI_VERSION` | `1.0.0` | `@earendil-works/pi-coding-agent` |
| `BASEDPYRIGHT_VERSION` | `1.40.2` | basedpyright |
| `BLACK_VERSION` | `26.10.0` | black |
| `PI_SYNC_REPO` | `https://github.com/Glyochi/pi-config-sync.git` | config repo |
| `PI_SYNC_REF` | `main` | config repo tag/branch/commit to bake |
| `PI_SYNC_BRANCH` | `main` | branch the entrypoint fast-forwards to |
| `PI_GIT_USER` | `Glyochi` | user stored in the git credential |
| `LQS_REPO` | `https://github.com/Glyochi/linux-quick-setup.git` | repo cloned into `/linux-quick-setup` |
| `LQS_REF` | `main` | ref for that clone (CI passes the built commit) |
| `DEV_UID` / `DEV_GID` | `1000` | non-root `dev` user ids |

Pi extension versions are pinned in the config repo's `settings.json`
(`PI_SYNC_REPO`/`PI_SYNC_REF`). The image reads that file and seeds
`~/.pi/agent/npm` from it, and never writes to it.

Notes:
- Runs as the non-root `dev` user with the code mounted at `/workspace`. Use
  `--build-arg DEV_UID=$(id -u) --build-arg DEV_GID=$(id -g)` when your host uid
  is not 1000, so files written to the mount are not root-owned.
- `dev` has passwordless `sudo` (`/etc/sudoers.d/dev`), so runtime installs work:
  `sudo apt-get update && sudo apt-get install -y <pkg>`. Those are ephemeral —
  rebuild the image to keep a package.
- The config repo is public by default and needs no token; a private one can be
  built with a BuildKit secret, and any token is never written into an image layer.
- Runtime rehydration is pull-only; if the config repo's history diverged, the
  container resets to the remote, so container-local config changes are ephemeral.
- `amd64` and glibc bases only (no Alpine/musl, no arm64). `debian:bookworm-slim`
  is the only built and verified base.
- `fd` is installed from the base's `fd-find` package (symlinked to `fd`), so Pi
  does not download it on first run.

# Other dependencies 
- black (formating)
- opencode
    - for debugging `pgrep -af 'opencode.*--port`
    - for cleaning `pgrep -f 'opencode.*--port' | xargs -r kill -9`

