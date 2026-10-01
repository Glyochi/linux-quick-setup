#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail

# Remove pi config, packages and cached installs
print_info "Removing pi configuration...\n"
rm -rf "$HOME/.pi"

# Remove the pi binary symlink
print_info "Removing pi binary...\n"
rm -f "$HOME/.local/bin/pi"

print_info "Removed pi successfully!\n"
print_info "The pi-config repository was left untouched.\n"
