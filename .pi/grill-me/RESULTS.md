# Grill Me Results

Generated: 2026-10-06T23:53:02.613Z

## Plan

Read this repo and see how neovim and opencode is integrated. I want to replace opencode with pi. I'm looking at pi.nvim as a potential extensions to integrate it into neovim, but research alternatives

## Shared Understanding

Replace the opencode Neovim integration with a pi integration. opencode is removed entirely (plugin spec, CLI installer, docs). The chosen shape is an external bridge: pi runs in its own tmux pane and Neovim sends context/prompts into that live session over a unix socket. The bridge is carderne/pi-nvim v0.2.5 (tag commit b10a31ad13321ec5ac80c7e2567dd4f8d42c9980), whose pi-side extension is installed via `pi install npm:pi-nvim` and recorded in the separate pi-config-sync repo's settings.json. Existing <leader>k* keymap slots are reused with their original intent. No tmux launcher is added. Work stays in the working tree on main with no commit or push.

## Questions and Answers

### 1. Which interaction shape should the pi↔Neovim integration take?

**Recommended answer:** Side terminal TUI (keep current shape)

**User answer:** Pi outside nvim, socket bridge

**Status:** resolved

**Notes:** Chose the external-tmux-bridge shape. This makes the pi process live outside Neovim and the plugin context/prompt-only, so the opencode 'toggle terminal' and <C-u>/<C-d> scroll keymaps no longer map cleanly.

### 2. What should happen to opencode in this repo?

**Recommended answer:** Remove opencode entirely

**User answer:** Remove opencode entirely

**Status:** resolved

**Notes:** Scope includes neovim/lua/gly_custom/plugins/opencode.lua, install_dependencies.sh curl line, README 'Other dependencies' section, and AGENTS.md references.

### 3. Which keymap prefix should drive the pi integration?

**Recommended answer:** Reuse <leader>k*

**User answer:** Reuse <leader>k*

**Status:** resolved

**Notes:** Keeps existing muscle memory; exact per-key mapping still to be decided since toggle/scroll semantics are gone.

### 4. How should the plugin handle project-level agent config?

**Recommended answer:** Drop project-config detection

**User answer:** Drop project-config detection

**Status:** resolved

**Notes:** Removes the .ai/opencode.json + OPENCODE_CONFIG logic; pi auto-discovers AGENTS.md and .pi/ from its own cwd.

### 5. When you toggle the pi panel open, which session should start?

**Recommended answer:** Continue last session

**User answer:** Continue last session

**Status:** resolved

**Notes:** With an external bridge the plugin does not spawn pi, so continuation must be a pi CLI flag (pi -c) or the session picker; depends on whether the repo adds a tmux launcher.

### 6. Where should this work land?

**Recommended answer:** New branch off main

**User answer:** Work on main, but dont commit or push

**Status:** resolved

**Notes:** Plan must produce working-tree edits only: no commits, no pushes. dev-pi branch is stale (no commits beyond main).

### 7. Which socket-bridge implementation should the Neovim side use?

**Recommended answer:** carderne/pi-nvim v0.2.5

**User answer:** carderne/pi-nvim v0.2.5

**Status:** resolved

**Notes:** Verified compatible: the extension calls sendUserMessage(msg, {deliverAs:"followUp"}), which exists in the pinned pi 1.0.0 ExtensionAPI. Tag v0.2.5 points at commit b10a31ad13321ec5ac80c7e2567dd4f8d42c9980. Plugin's default keymaps must be disabled to avoid clobbering visual-mode <leader>p paste in remap.lua.

### 8. Where should the pi-side extension (the socket server that pi loads) be declared?

**Recommended answer:** pi-config-sync settings.json via pi install

**User answer:** pi-config-sync settings.json via pi install

**Status:** resolved

**Notes:** Recorded in ~/.pi/agent/settings.json in the separate pi-config-sync repo; this repo only documents the prerequisite. ~/.pi/agent/settings.json currently lists 10 packages and is synced by pi-config-sync.

### 9. How should the <leader>k* keys map onto the bridge's commands?

**Recommended answer:** Mirror today's opencode slots

**User answer:** Mirror today's opencode slots

**Status:** resolved

**Notes:** <leader>kk=:PiSend, <leader>ka=:PiSendBuffer, <leader>kh=:PiSendSelection (visual), <leader>kx=:Pi dialog, <leader>kp=:PiPing, <leader>ks=:PiSessions. Drop <C-u>/<C-d> scroll bindings.

### 10. Should the repo also launch pi for you, or assume a pi session is already running?

**Recommended answer:** Assume pi is already running

**User answer:** Assume pi is already running

**Status:** resolved

**Notes:** No tmux launcher code. README must document starting pi in a tmux pane with `pi -c` to continue the last session; pi and nvim must share the same container so /tmp/pi-nvim-sockets is shared.

### 11. What automated verification should the plan require?

**Recommended answer:** Repo-standard checks plus a headless load check

**User answer:** Repo-standard checks, Headless plugin load + command assertions

**Status:** resolved

**Notes:** bash -n + shellcheck on touched scripts, headless dofile smoke on the new plugin spec and neovim/init.lua, plus a headless nvim run that calls setup() and asserts the :Pi* commands and keymaps exist. End-to-end bridge behaviour stays a user check.

### 12. Removing the opencode curl leaves install_dependencies.sh with no functional content. What should happen to it?

**Recommended answer:** Keep as a placeholder

**User answer:** Delete the file

**Status:** resolved

**Notes:** Delete install_dependencies.sh; update AGENTS.md repository map, drop the 'Dependency setup only' run command, and remove the file from both the bash -n and shellcheck command lists.

## Agreed Decisions

- Interaction shape: external tmux/socket bridge — pi runs outside Neovim; Neovim only sends prompts and context.
- Bridge implementation: carderne/pi-nvim pinned to v0.2.5 (commit b10a31ad13321ec5ac80c7e2567dd4f8d42c9980).
- Verified compatibility: the extension's sendUserMessage(msg, {deliverAs:"followUp"}) exists in the pinned pi 1.0.0 ExtensionAPI.
- Pi-side extension install: `pi install npm:pi-nvim`, recorded in ~/.pi/agent/settings.json in the separate pi-config-sync repo; this repo documents it as a prerequisite only.
- opencode is removed entirely: opencode.lua, the install_dependencies.sh curl, the README 'Other dependencies' section, and AGENTS.md references.
- install_dependencies.sh is deleted; AGENTS.md repository map, the 'Dependency setup only' command, and the bash -n / shellcheck file lists are updated accordingly.
- Keymaps reuse the <leader>k* prefix with today's intent: <leader>kk = :PiSend, <leader>ka = :PiSendBuffer, <leader>kh = :PiSendSelection (visual), <leader>kx = :Pi dialog, <leader>kp = :PiPing, <leader>ks = :PiSessions; the <C-u>/<C-d> scroll bindings are dropped.
- The plugin's default keymaps are disabled (set_default_keymaps = false) so visual-mode <leader>p paste in remap.lua is not clobbered.
- No tmux launcher: pi is assumed to already be running; README documents `pi -c` in a tmux pane for continuing the last session.
- Project-level config detection (.ai/opencode.json + OPENCODE_CONFIG) is dropped; pi auto-discovers AGENTS.md and .pi/ from its own cwd.
- Session continuation is handled by pi itself (`pi -c`), not by the Neovim plugin.
- Verification: repo-standard bash -n / shellcheck on touched scripts, headless dofile smoke on the new plugin spec and neovim/init.lua, plus a headless nvim run asserting the :Pi* commands and keymaps exist.
- Work happens on main in the working tree only — no commit, no push.

## Open Risks

- carderne/pi-nvim declares peerDependency @earendil-works/pi-coding-agent ^0.74.0 while this repo pins PI_VERSION=1.0.0. The import is type-only and erased at runtime, but `pi install` / npm may emit a peer warning; the Dockerfile seed path uses --legacy-peer-deps, the plain `pi install` path is unverified.
- The bridge requires pi and Neovim to share a filesystem namespace so /tmp/pi-nvim-sockets is visible to both. Running pi on the host and Neovim inside the container will silently fail to discover the socket.
- carderne/pi-nvim is a young third-party project (92 stars, created Mar 2026). Its extension targets a moving pi ExtensionAPI, so a future pi upgrade can break the socket server even though the Neovim side is pinned.
- The plugin's setup() starts a 1-second uv timer that calls checktime whenever a pi socket is reachable; this runs for the whole Neovim session once loaded eagerly.
- End-to-end behaviour (socket discovery, prompt injection, cwd preference) cannot be proven headlessly — it requires a live pi session plus tmux, so it remains a user check.
- Pinning the pi-side extension version is a decision that lives in the pi-config-sync repo, not this one; documenting a bare `npm:pi-nvim` allows the two sides to drift out of sync.

## Next Decision Needed

None — all identified ambiguities are resolved.
