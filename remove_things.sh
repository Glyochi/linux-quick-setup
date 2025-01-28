#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail

# Remove lazy vim installed plugins
print_info "Removing neovim installed plugins...\n"
rm -r ~/.local/share/nvim

# Remove neovim vim configured lua files
print_info "Removing neovim lua configuration files...\n"
rm -r ~/.config/nvim

print_info "Removed neovim successfully!\n"


