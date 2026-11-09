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

Requires a Nerd Font in the terminal: nvim-tree's file and folder icons come from
`nvim-web-devicons` and use Nerd Font glyphs from the Private Use Area, so without one they
render as tofu boxes. Install **Hack Nerd Font** on the machine and select it as the terminal
font — fonts belong to the terminal, so the container cannot supply them. If an icon shows up
as `_` instead of tofu, that is the tmux locale issue described in the tmux section.

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

## Opt-in learning / Obsidian

The synced Pi config integrates [amosblomqvist/learn](https://github.com/amosblomqvist/learn):
foundation-first teaching, graded quizzes, web verification, Mermaid/SVG makers,
and optional Obsidian session notes. It retains the existing `pi-subagents` and
collapsible rpiv `ask_user_question`; the teaching workflow **does not activate
for normal coding explanations**. Toolkit commands/skills use `learn-`, extension
tools use `learn_` (for example `learn_quiz`), and agents use `learn.`.
The extension bundle lives in `~/.pi/agent/extensions/learn/`, and the visual skill
is `/skill:learn-visualize`. Agents inherit your current model rather than
requiring the author's providers. Use a vision-capable model for verified visuals.

After syncing the new config, run `/reload`, then `/learn-doctor` in Pi:

```text
/learn-log /workspace/Notes/Lesson.md
/skill:learn-teach Explain TCP reliability, starting from what I already know
```

The note must already exist. `/learn-log` appends an idempotent backfill without
replacing existing prose; `/learn-unlog` stops it. Open that same note in Obsidian
on the host: questions appear without their answers, then answers and feedback
are added after submission. Makers save unique PNGs into `viz/` beside the note
and embed them with Obsidian wikilinks. Without logging, output defaults to
`<cwd>/viz`. Notes and images stay outside the synced config repository.

The vault must be mounted into the container, not merely named with a host-only
path. For example, `bash run_container.sh "$HOME/ObsidianVault" learning` mounts
that vault as `/workspace`; Obsidian keeps running on the host. Pi and Obsidian
then read the same files. In quizzes, `Ctrl+]` hides/reopens the overlay,
`PgUp`/`PgDn` scroll, and `Tab` focuses an optional answer note.

The Docker image includes Chromium, `rsvg-convert`, and fonts.
`install_pi.sh` installs the toolkit's locked npm dependencies when the synced
config contains it. For an existing container, or host-only setup:

```bash
bash install_pi_learn.sh                 # locked npm dependencies only
bash install_pi_learn.sh --system-deps   # Debian/Ubuntu: system packages too
```

Use `PI_CODING_AGENT_DIR` for a non-default Pi config directory. On other Linux
distros, install Chromium, librsvg, and fonts through your system package manager,
then run the npm-only helper. `PI_LEARN_CHROME` can select a browser executable.
The image disables Chromium's own sandbox inside Docker; hosts keep it enabled.
See `~/.pi/agent/extensions/learn/README.md` for safety notes and overrides.
Pi does not install local extension dependencies on `/reload`: rerun the helper
when the synced dependency lock changes, or rebuild the image.

The integration is split across **two repos**: this repo owns the installer and
Docker environment; the Pi config repo owns the skills, agents, extension, and
npm lock. Sync/push the config and setup changes before recreating a container,
and build with a `PI_SYNC_REF` that includes the toolkit. Older config refs skip
it. The Docker build runs the toolkit's native `node:test` suite and real render
smokes when those tests are present:

```bash
bash tests/install_pi_learn.sh  # isolated installer checks; no network or root access
npm test --prefix ~/.pi/agent/extensions/learn
PI_LEARN_RENDER_SMOKE=1 npm test --prefix ~/.pi/agent/extensions/learn
```

## Neovim + pi

There is **one** pi process — running in its own tmux session — and two ways to reach it from
Neovim:

1. **The mirror split** — `<leader>kk` attaches a right-hand vertical split to the tmux pane
   running pi as a second tmux client (`gly_custom/pi_terminal.lua`). Because it is the same
   process, the split shows the live transcript: whatever pi does appears in the split and
   the tmux window at once, and you can type in either. Press it again to hide the split
   while pi keeps running, and a third time to restore it.
   The pane is chosen by directory, and only by directory: the pi whose working directory is
   Neovim's working directory (`:pwd`, so `:cd` moves the match), which is the pi for this
   project. If Neovim's directory is unusable — it was deleted while Neovim was running — the
   mirror says so and tells you which `:cd` fixes it. If two pi panes share that directory,
   `<leader>kk` opens nothing and lists them so you can close one; if none does, it lists any
   pi panes found elsewhere and the command to start one here. The mirror only sees pi **in a
   tmux pane**: a pi started outside tmux has no pane for the split to attach to, so
   `<leader>kk` reports that no pi pane was found in this directory.
2. **The socket bridge** — the [`carderne/pi-nvim`](https://github.com/carderne/pi-nvim)
   bridge, pinned to `v0.2.5` in `neovim/lua/gly_custom/plugins/pi.lua`, sends prompts and
   context from the editor into that **already running** pi session over a unix socket. Pi
   keeps its own full TUI in tmux, so the session tree, model switching, and extensions
   behave exactly as they do in the terminal. The plugin's own `<leader>p` defaults are
   disabled so visual-mode paste from `remap.lua` still works.

The two paths meet in one rule: **every prompt from Neovim goes over the socket to the
tmux-hosted pi.** Nothing is pasted into a terminal buffer, so the prompt always lands in
the one process that owns the session. That is what makes an `ask_user_question`
questionnaire appear in the tmux window — where it can be answered full screen — and in the
mirror split at the same time. A second `pi -c` process cannot do this: pi has no
cross-process reload or attach, each process keeps its own in-memory transcript, and the
questionnaire is rendered in the process that raised it, so the other window would only ever
show a stale copy (and a stale writer appends to its own last entry, branching the session
tree).

### How it is wired

| File | Role |
| --- | --- |
| `neovim/lua/gly_custom/plugins/pi.lua` | Pins `carderne/pi-nvim` to `v0.2.5`, disables its default `<leader>p` maps, and owns the `<leader>k*` keymaps. |
| `neovim/lua/gly_custom/pi_terminal.lua` | `<leader>kk`: resolves the **interactive TUI** pi pane whose `pane_current_path` is Neovim's `:pwd` (tmux panes only; headless pi panes are ignored), groups a private `pi-mirror-<pane id>` session with that pane's session, and attaches the split with `tmux attach-session -f ignore-size -t pi-mirror-<pane id>`; hides it with `nvim_win_hide()` (pi keeps running) and restores the same view on the next press. `is_pi_terminal()` matches the `term://{cwd}//{pid}:{cmd}` buffer name of that attach command, `toggle()` notifies instead of opening anything when the directory is ambiguous or holds no pi pane, and a `TermClose` autocmd removes the mirror session when the split closes. |
| `neovim/lua/gly_custom/pi_prompt.lua` | `<leader>kh` / `<leader>ka`: the reference/prompt float. `compose()` builds the message, `next_context()` cycles `selection` / `file`, and `deliver()` always sends it over the pi-nvim socket. |
| `neovim/init.lua` | Maps `<C-w>` in terminal mode to `<C-\><C-n>`, so one `<C-w>` leaves the pi split's terminal buffer for normal-mode navigation. |

Behaviour worth knowing:

- `-f ignore-size` on the mirror client keeps the split from resizing the window the fullscreen tmux client is using, so the split shows the top-left crop when it is narrower. Both clients are on the same server, so the prefix is shared: copy-mode in the split is `C-b C-b [` while Neovim runs inside tmux, and a plain `C-b [` when it does not.
- The mirror lives in its own `pi-mirror-<pane id>` session, grouped with the pi session: it shares the windows but keeps an independent current window, so attaching the split never moves your outer client, and closing the split removes the mirror session again. Selecting the pi pane moves the shared window's active pane, which only matters when that window holds several panes. The name is per pi pane, so **two Neovim instances in different directories each get their own mirror**; matching uses tmux window/pane ids (not `0.0` indices, which every session shares), so a second Neovim cannot latch onto the first one's pi.
- Only the **interactive pi TUI** is a mirror target. A headless pi run in a pane — a subagent (`--mode rpc`), or `pi -p`/`--print` — is ignored, so it is neither mirrored nor counted as a second pi in the directory. Detection is tmux's `#{alternate_on}` (a full-screen TUI owns the alternate screen), plus pi's terminal title for the `--tui-mode regular` case.
- The tmux-hosted pi keeps the synced `fullscreen` TUI mode from `~/.pi/agent/settings.json`; the mirror shows that same screen.
- `carderne/pi-nvim`'s setup enables `autoread` and, while a socket is reachable, runs `checktime` about once a second, so files pi edits reload in Neovim automatically.
- Typing in the split goes to the same pi, so modified keys such as `Shift+Enter` reach it only when Neovim and the outer terminal/multiplexer forward extended keys (the shipped tmux config enables that for tmux-hosted sessions). `Ctrl+J` always inserts a newline in pi.

### The prompt float

`<leader>kh` (visual) and `<leader>ka` (normal) open a floating prompt box
(`gly_custom/pi_prompt.lua`) stacked in one centered column:

- The **reference** pane on top is read-only and shows only what is being referenced:
  `@lua/a.lua` for a file, `@lua/a.lua lines 3-5` for a selection. When the buffer has
  unsaved edits it adds `⚠ unsaved changes; pi will read the saved file`, and an unnamed
  buffer shows `⚠ no file on disk; pi gets the prompt only`.
- The **prompt** pane directly below is where you type; it grows as you add lines.
- `<Tab>` cycles the reference between `selection` and `file` (staying on `file` when there
  is no visual selection); the top pane updates each time.
- `<CR>` sends, `<C-j>` inserts a newline, and `<Esc>` / `<C-c>` cancel without sending.

The message carries a **relative `@path` reference instead of inlined content**, so pi reads
the file from disk. That keeps prompts small, but unsaved buffer edits are not included: the
reference pane flags them before you send. For the same reason the reference only resolves
when pi shares Neovim's working directory.

On send, the message goes over the pi-nvim socket to the tmux-hosted pi and is submitted
there. Nothing is pasted into the mirror split, so the prompt, the answer, and any
questionnaire all belong to that one session; the split shows them because it is a view of
the same process.

### Prerequisite

The socket server is a pi extension, so pi has to load it. It is declared in the Pi
config repo rather than here, so it syncs to every machine. Every prompt from Neovim
travels over this socket, so without it the float cannot send anything:

```sh
pi install npm:pi-nvim@0.2.5
```

That records the package in `~/.pi/agent/settings.json` (the `pi-config-sync` checkout).
Run `/reload` in pi, or restart it; `/pi-nvim-info` then reports the socket path.

### Usage

Use `<leader>kk` for the split view of pi, and `<leader>ka` / `<leader>kh` to send from
Neovim. pi itself runs in tmux, so it keeps going when Neovim closes:

```sh
tmux new-session -A -s pi 'pi -c'   # -c continues the last session for this directory
```

Start pi from the directory you work in: the mirror finds it by that directory, so the
session name is only a label.

| Key | Mode | Action |
| --- | --- | --- |
| `<leader>kk` | n | Toggle the pi mirror split (hiding keeps pi running) |
| `<leader>kh` | x | Prompt float, reference defaulting to the visual selection |
| `<leader>ka` | n | Prompt float, reference defaulting to the current file |
| `<leader>kp` | n | `:PiPing` — check the socket |
| `<leader>ks` | n | `:PiSessions` — list running pi sessions |

The plugin's own `:Pi`, `:PiSend`, `:PiSendBuffer` and `:PiSendSelection` commands remain
available; they are simply no longer bound to keys. They still inline file/selection content
— the float is the reference-only path.

If a send does not land, run `:PiPing` first: it separates "no pi session is
reachable" from "the prompt was sent". `:PiSessions` shows which session the plugin
picked — it prefers one whose working directory matches Neovim's, and falls back to the
most recent socket otherwise.

### Shared filesystem requirement

The bridge finds sessions through `/tmp/pi-nvim-sockets`, so pi and Neovim must see the
same `/tmp`. Both inside the container works, and both on the host works, but **pi on the
host with Neovim inside the container will never connect**, because the socket manifests
are not shared.

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
- `mouse on`, which enables mouse selection, scrolling, and pane/window selection.

Notes:

- Interactive shells in the image alias `tmux` to run with `TERM=xterm-256color`.
- The image sets `LANG=C.UTF-8` and Compose pins the same value, because tmux only treats a client
  as UTF-8 when `TMUX` is set or the locale contains `UTF-8`. Without a UTF-8 locale tmux replaces
  non-ASCII glyphs that have no ACS mapping — rounded box corners (`╭ ╮ ╰ ╯`) and Nerd Font icons in
  `pi` and `nvim-tree` — with `_`. Keep a UTF-8 locale if you override the environment.
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
- The pin is **3.6b, not 3.7.x**: tmux 3.7 reworked session sorting and broke
  `choose-tree` (and so `C-b w` / `C-b s`) whenever a session group exists — the
  tree comes up blank and the first key closes it. The pi mirror split relies on a
  session group, so it triggered this on every open. Upstream fixed it in 3.8
  (tmux commit `a6a06c5a`), but `tmux-builds` has no 3.8 static release yet; move
  the pin to 3.8 once it does.

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

Run it. The entrypoint fast-forwards the baked Pi config **and** the
`/linux-quick-setup` checkout to their origin branches (public repos need no
token) and never pushes:

```bash
docker run --rm -it \
  -v "$PWD:/workspace" \
  linux-quick-setup:latest
```

Use `nvim`, `pi`, `tmux`, and GitHub CLI (`gh`) inside the container. System pip is
configured with `break-system-packages = true` in `/etc/pip.conf`. Add
`-e GITHUB_TOKEN` only for a private repo, or set `PI_SYNC_REHYDRATE=0` (Pi config)
or `LQS_SYNC_REHYDRATE=0` (`/linux-quick-setup`) to skip either fetch.

The container has no git identity, and pi-config-sync's automatic sync commits
need one. Set `GIT_USER_NAME`/`GIT_USER_EMAIL` (the entrypoint applies them at
startup) or run `setup-git-auth` before starting pi, otherwise the sync fails
with `Author identity unknown`.

## Editing linux-quick-setup in the container

The image ships a real git checkout of this repo at `/linux-quick-setup` with an
`origin` remote. `~/.config/nvim` symlinks into `/linux-quick-setup/neovim`, so
edits there take effect immediately in Neovim and show up in `git status`.
`vim` and `vi` are aliased to `nvim`, and `tmux` is aliased to run with
`TERM=xterm-256color`, in the login profile and `~/.bashrc`.
`~/.tmux.conf` symlinks into `/linux-quick-setup/tmux/.tmux.conf` the same way;
restart the tmux server (`tmux kill-server`) for config changes to take effect.

Every container start fast-forwards this checkout to `origin/main`
(`LQS_SYNC_BRANCH` picks another branch) and resets it to the remote when it
cannot fast-forward, so **unpushed edits in `/linux-quick-setup` are ephemeral**:
push them, or start the container with `LQS_SYNC_REHYDRATE=0` to keep the
checkout as it is. The same pull-only refresh applies to the Pi config repo.

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
matches your tree instead of `main`. At runtime the entrypoint then follows
`LQS_SYNC_BRANCH` (default `main`), so a baked ref that is not `main` is
fast-forwarded onto `main` at the next start unless `LQS_SYNC_REHYDRATE=0`.

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

## Quick launcher (`run_container.sh`)

`run_container.sh` brings the container up in the background and drops you into
a shell inside it:

```bash
bash run_container.sh /projects/app                    # name defaults to app
bash run_container.sh /projects/app myapp              # explicit name
bash run_container.sh /projects/app myapp nvim         # one-off command
bash run_container.sh /projects/app '' tmux new -As main # default name + command
```

It is the equivalent of:

```bash
CONTAINER_NAME=mytool CODE_DIR=/path/to/mytool docker compose -p mytool up -d
docker compose -p mytool exec dev bash -l
```

Because the container starts detached, losing the terminal connection (or
closing the laptop) no longer stops it: tmux and any running `pi` session inside
keep going, and re-running the script simply re-attaches. `docker-compose.yaml`
stays the single source of truth for `IMAGE`, `IMAGE_TAG`, `BASE_IMAGE`,
`DEV_UID`/`DEV_GID`, `GITHUB_TOKEN`, and the `PI_SYNC_*` and `LQS_SYNC_*`
variables, which are passed through to Compose;
`BUILD=1 bash run_container.sh` adds `--build`, and `SERVICE`/`COMPOSE_FILE`
override the service and compose file.

Usage: `bash run_container.sh [path] [container-name] [command...]`.
The first argument is the code path; the second is the optional container name.
The name defaults to the path's last folder (lowercased, with unsupported
characters replaced by `-`). With no path, the Compose file's directory is used.
Relative paths are resolved from the launcher's current working directory.
`CODE_DIR` and `CONTAINER_NAME` environment variables are ignored by the launcher
(they remain supported for direct Compose calls). Pass `''` as the second
argument to use the default name when supplying a command.

Each container name gets its own Compose project, so different names can run
concurrently without replacing each other. Project names follow the container
name; names containing uppercase letters or dots are normalized with a checksum
suffix to keep them distinct. Pi sessions, state, and login volumes are separate
per project; a new project may require a new Pi login. Existing volumes are not
removed. Reusing a name reattaches to that container (changing its code path
recreates that same container). Folders with the same basename need explicit,
distinct names:

```bash
bash run_container.sh /projects/frontend
bash run_container.sh /projects/backend
bash run_container.sh /projects/frontend frontend-test
```

Kitty's `TERM=xterm-kitty` is mapped to `xterm-256color` for exec because the
image lacks Kitty terminfo; other terminal settings, including SSH, are unchanged.

That shell comes from `docker compose exec`, which never goes through docker's
detach-key proxy, so a lone **Ctrl+P** arrives intact (Pi's model cycling,
readline history). Only attaching to the container's own stdio is affected —
`docker compose up` without `-d`, or `docker attach` — because the CLI holds
`Ctrl+P` as the first key of the default `ctrl-p,ctrl-q` detach sequence until
the next key decides whether it is a detach. For those, set `"detachKeys"` in
the docker CLI config (`~/.docker/config.json`) or pass `--detach-keys`:

```bash
docker run --rm -it --detach-keys="ctrl-^,ctrl-^" \
  -v "$PWD:/workspace" \
  ghcr.io/glyochi/linux-quick-setup:latest
```

## Docker Compose

`docker-compose.yaml` wraps the same image, mounting the code at `/workspace`
and keeping Pi sessions and machine state in named volumes:

```bash
docker compose up --build
# one-off:
docker compose run --rm dev nvim
```

Override `CODE_DIR`, `BASE_IMAGE`, `IMAGE_TAG`, `TMUX_VERSION`, `PI_SYNC_REF`,
`DEV_UID`/`DEV_GID`, `PI_SYNC_REHYDRATE`, `LQS_SYNC_BRANCH`, or
`LQS_SYNC_REHYDRATE` through the environment or a `.env` file. The Pi login persists in the `pi-auth` volume, so `pi` stays signed in
across runs — run `/login` once. To reuse an existing host login instead, follow
the commented volume in `docker-compose.yaml`.

## GUI windows / OpenCV `imshow` (Linux and Wayland)

Compose (including `run_container.sh`) forwards the host's `DISPLAY` and mounts
its X11 socket. On Wayland this uses **XWayland**; native Wayland forwarding is
not needed. The image includes the common OpenCV/Qt X11 runtime libraries, and
Compose forces Qt's `xcb` (X11) backend. No privileged mode or GPU passthrough
is required for basic `imshow` windows.

### Host setup

Install the host tools once:

```bash
# Arch (including Wayland desktops):
sudo pacman -S --needed xorg-xwayland xorg-xhost

# Debian / Ubuntu:
sudo apt-get update && sudo apt-get install -y xwayland x11-xserver-utils
```

From a terminal **inside your graphical desktop session**, before starting the
container (repeat after logging out/rebooting):

```bash
echo "$DISPLAY"   # should show something like :0 or :1
xhost +local:
bash run_container.sh
```

If `DISPLAY` is empty on Wayland, enable XWayland in your compositor/session
and reopen the terminal; don't guess a display number. Plain X11 sessions
already have an X server and don't need XWayland.

**This deliberately allows all local users/containers to access your X display,
including observing input/windows.** To revoke that access, run `xhost -local:`
on the host. Neither command needs `sudo`. This setup targets a local Linux
Docker engine, not Docker Desktop or an SSH-forwarded display.

For an existing image, build once to include the GUI libraries:

```bash
BUILD=1 bash run_container.sh
```

The launcher applies the Compose changes automatically, recreating an existing
container if necessary (files outside volumes/bind mounts will be lost).
Use your usual path/name arguments to target the same container.

### Inside the container

Install the GUI-enabled OpenCV package in your project's Python environment;
**do not use `opencv-python-headless`** or mix multiple OpenCV packages in the
same environment. For a fresh environment:

```bash
python3 -m pip install opencv-python
python3 - <<'PY'
import cv2
import numpy as np

cv2.imshow("Container display test", np.zeros((300, 500, 3), dtype=np.uint8))
cv2.waitKey(0)  # pumps GUI events; press a key in the window to close it
cv2.destroyAllWindows()
PY
```

For direct `docker run` instead of Compose, pass the display settings yourself
(after the same host `xhost` command):

```bash
docker run --rm -it \
  -e DISPLAY="$DISPLAY" -e QT_QPA_PLATFORM=xcb \
  -v /tmp/.X11-unix:/tmp/.X11-unix:ro \
  -v "$PWD:/workspace" \
  ghcr.io/glyochi/linux-quick-setup:latest
```

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
| `TMUX_VERSION` | `3.6b` | tmux static build from `tmux-builds` (image only; see the tmux note) |
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
- Runtime rehydration is pull-only and runs for both the Pi config repo and the
  baked `/linux-quick-setup` checkout; if either history diverged (or local
  changes are in the way), the container resets that checkout to the remote, so
  container-local changes — including unpushed `/linux-quick-setup` edits — are
  ephemeral.
- `amd64` and glibc bases only (no Alpine/musl, no arm64). `debian:bookworm-slim`
  is the only built and verified base.
- `fd` is installed from the base's `fd-find` package (symlinked to `fd`), so Pi
  does not download it on first run.

# Other dependencies 
- black (formating)

