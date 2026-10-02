#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail

# Remove pi config, packages and cached installs.
# This also removes the local pi-config-sync checkout at ~/.pi/agent; the
# synced configuration itself remains on the remote and can be re-cloned with
# install_pi.sh.
print_info "Removing pi configuration...\n"
rm -rf "$HOME/.pi"

# Remove the pi binary symlink
print_info "Removing pi binary...\n"
rm -f "$HOME/.local/bin/pi"

print_info "Removed pi successfully!\n"
print_info "The synced config remains on the remote; re-run install_pi.sh to restore it.\n"
