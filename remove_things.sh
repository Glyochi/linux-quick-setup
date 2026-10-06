#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail

# Remove lazy vim installed plugins
print_info "Removing neovim installed plugins...\n"
sudo rm -r ~/.local/share/nvim

# Remove neovim vim configured lua files
print_info "Removing neovim lua configuration files...\n"
rm -r ~/.config/nvim

# Remove the tmux config symlink. Only a symlink is removed, so a real user
# config is never deleted.
if [[ -L ~/.tmux.conf ]]; then
	print_info "Removing tmux config symlink...\n"
	rm -f ~/.tmux.conf
fi

print_info "Removed neovim successfully!\n"


