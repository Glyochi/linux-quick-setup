#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail

PI_CONFIG_DIR="${PI_CONFIG_DIR:-$HOME/pi-config}"
PI_CONFIG_REPO="${PI_CONFIG_REPO:-}"

# A freshly installed pi binary may not be on PATH in this shell yet.
export PATH="$HOME/.local/bin:$PATH"

print_info "Setting up pi...\n"

### Install pi if it is missing
if command -v pi >/dev/null 2>&1; then
	print_info "pi is already installed ($(pi --version 2>/dev/null || echo 'unknown version')).\n"
else
	print_default "Installing pi...\n"
	install_response="$(curl -fsSL https://pi.dev/install.sh | sh || echo 'False')"
	if [[ "$install_response" == "False" ]] || ! command -v pi >/dev/null 2>&1; then
		print_error "Failed to install pi. See https://pi.dev for manual installation.\n"
		exit 1
	fi
	print_info "Installed pi successfully.\n"
fi

### Fetch pi-config: separate repo holding settings, skills and extensions
if [[ -d "${PI_CONFIG_DIR}/.git" ]]; then
	print_default "Updating pi-config at '${PI_CONFIG_DIR}'...\n"
	if ! git -C "${PI_CONFIG_DIR}" pull --ff-only; then
		print_warning "Could not update pi-config; continuing with the local checkout.\n"
	fi
elif [[ -n "${PI_CONFIG_REPO}" ]]; then
	print_default "Cloning pi-config from '${PI_CONFIG_REPO}'...\n"
	if ! git clone "${PI_CONFIG_REPO}" "${PI_CONFIG_DIR}"; then
		print_error "Failed to clone pi-config from '${PI_CONFIG_REPO}'.\n"
		exit 1
	fi
else
	print_error "pi-config was not found at '${PI_CONFIG_DIR}' and PI_CONFIG_REPO is not set.\n"
	print_error "Set PI_CONFIG_REPO='git@github.com:<you>/pi-config.git' and re-run, or create '${PI_CONFIG_DIR}' first.\n"
	exit 1
fi

### Link settings and reconcile packages
if [[ ! -f "${PI_CONFIG_DIR}/install.sh" ]]; then
	print_error "'${PI_CONFIG_DIR}/install.sh' is missing.\n"
	exit 1
fi
bash "${PI_CONFIG_DIR}/install.sh"

print_info "Pi setup complete. Run 'pi' and use '/login' to authenticate.\n"
