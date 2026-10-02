#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail

# pi-config-sync keeps the pi agent directory itself as the git repository, so
# this script clones/updates that repo instead of a separate pi-config checkout.
PI_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
PI_SYNC_REPO="${PI_SYNC_REPO:-https://github.com/Glyochi/pi-config-sync.git}"
PI_GIT_USER="${PI_GIT_USER:-Glyochi}"
PI_SYNC_PACKAGE="${PI_SYNC_PACKAGE:-npm:pi-config-sync}"

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

### Authenticate git for a private HTTPS config repository
# The token is stored once per machine in ~/.git-credentials. SSH remotes skip
# this and rely on the machine's SSH key instead.
if [[ "$PI_SYNC_REPO" == https://* ]]; then
	git config --global credential.helper store
	if ! printf 'protocol=https\nhost=github.com\n\n' | git credential fill >/dev/null 2>&1; then
		if [[ ! -t 0 ]]; then
			print_error "'${PI_SYNC_REPO}' is private and no GitHub credential is stored.\n"
			print_error "Add a token to ~/.git-credentials (or set PI_SYNC_REPO to an SSH URL), then re-run.\n"
			exit 1
		fi
		print_default "The config repo is private, so git needs a GitHub token.\n"
		print_default "Create a classic token with the 'repo' scope: https://github.com/settings/tokens\n"
		read -rsp "Paste GitHub token: " github_token
		echo
		if [[ -z "$github_token" ]]; then
			print_error "No token provided; cannot access '${PI_SYNC_REPO}'.\n"
			exit 1
		fi
		printf 'https://%s:%s@github.com\n' "$PI_GIT_USER" "$github_token" >> "$HOME/.git-credentials"
		unset github_token
		chmod 600 "$HOME/.git-credentials"
		print_info "Stored GitHub credential in ~/.git-credentials.\n"
	fi
fi

### Clone or update the pi agent config repository
if [[ -d "${PI_AGENT_DIR}/.git" ]]; then
	print_default "Updating pi config at '${PI_AGENT_DIR}'...\n"
	if ! git -C "${PI_AGENT_DIR}" pull --ff-only; then
		print_warning "Could not update pi config; continuing with the local checkout.\n"
	fi
elif [[ -e "${PI_AGENT_DIR}" ]]; then
	# pi was already run on this machine, so the agent directory exists but is
	# not yet a git repository. Preserve it (never delete) and clone fresh.
	backup_dir="${PI_AGENT_DIR}.bak.$(date +%Y%m%d%H%M%S)"
	print_warning "'${PI_AGENT_DIR}' already exists and is not a git repo; backing it up to '${backup_dir}'.\n"
	mv "${PI_AGENT_DIR}" "${backup_dir}"
	print_default "Cloning pi config from '${PI_SYNC_REPO}'...\n"
	if ! git clone "${PI_SYNC_REPO}" "${PI_AGENT_DIR}"; then
		print_error "Failed to clone pi config from '${PI_SYNC_REPO}'.\n"
		print_error "Your previous config is safe at '${backup_dir}'.\n"
		exit 1
	fi
else
	print_default "Cloning pi config from '${PI_SYNC_REPO}'...\n"
	if ! git clone "${PI_SYNC_REPO}" "${PI_AGENT_DIR}"; then
		print_error "Failed to clone pi config from '${PI_SYNC_REPO}'.\n"
		exit 1
	fi
fi

### Install the sync package (idempotent) so /gitsync is available
print_default "Installing ${PI_SYNC_PACKAGE}...\n"
if ! pi install "${PI_SYNC_PACKAGE}"; then
	print_error "Failed to install ${PI_SYNC_PACKAGE}.\n"
	exit 1
fi

print_info "Pi setup complete.\n"
print_info "Config repo '${PI_SYNC_REPO}' linked at '${PI_AGENT_DIR}'.\n"
print_info "Run 'pi', use '/login' for provider auth, and '/gitsync sync' to sync config.\n"
