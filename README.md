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
- Fresh machine: `bash install_pi.sh` (prompts once for a GitHub token)

On a new machine the script asks for a GitHub token with the `repo` scope,
stores it in `~/.git-credentials`, clones the config repo into `~/.pi/agent`,
and installs `npm:pi-config-sync`. After that, syncing is automatic (about
every 5 minutes and on shutdown); use `/gitsync status`, `/gitsync sync`,
`/gitsync pull`, or `/gitsync push` inside pi when you want to force it.

Skills live in `~/.pi/agent/skills/` and load in every project.

# Other dependencies 
- black (formating)
- opencode
    - for debugging `pgrep -af 'opencode.*--port`
    - for cleaning `pgrep -f 'opencode.*--port' | xargs -r kill -9`

