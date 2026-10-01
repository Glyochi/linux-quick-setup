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
Personal Pi configuration (settings, skills, extensions, prompts, themes)
lives in a separate repo so this bootstrap repo stays small.

- Install / refresh: `bash install_pi.sh`
- Teardown: `bash remove_pi.sh`
- Config repo default path: `~/pi-config`
- Fresh machine: `PI_CONFIG_REPO='git@github.com:<you>/pi-config.git' bash install_pi.sh`

Skills in `~/pi-config/skills/` load in every project. Project-specific skills
live under `~/pi-config/projects/<domain>/` and are declared in that project's
`.pi/settings.json`.

# Other dependencies 
- black (formating)
- opencode
    - for debugging `pgrep -af 'opencode.*--port`
    - for cleaning `pgrep -f 'opencode.*--port' | xargs -r kill -9`

