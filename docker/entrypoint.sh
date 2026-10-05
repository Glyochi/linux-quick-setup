#!/usr/bin/env bash
# Container entrypoint: optionally refresh the baked Pi config, then run the
# requested command. This is pull-only: it never commits or pushes. If the remote
# history diverged it resets to the remote, so container-local config changes
# stay ephemeral.
#
#   PI_SYNC_REHYDRATE=0     skip the network refresh entirely (use the baked ref)
#   GITHUB_TOKEN            optional classic `repo` token; also enables pushes
#   GIT_USER_NAME/EMAIL     optional commit identity for /linux-quick-setup
#   PI_SYNC_BRANCH          branch to fast-forward to (default: main)
#   PI_SYNC_FETCH_TIMEOUT   fetch timeout in seconds (default: 20)
set -Eeuo pipefail

PI_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
PI_SYNC_BRANCH="${PI_SYNC_BRANCH:-main}"
PI_SYNC_REHYDRATE="${PI_SYNC_REHYDRATE:-1}"
PI_SYNC_FETCH_TIMEOUT="${PI_SYNC_FETCH_TIMEOUT:-20}"

log(){ printf '[entrypoint] %s\n' "$*" >&2; }

# Persist the Pi login across container runs. auth.json is a symlink into the
# auth/ volume; pi writes it with writeFileSync, which follows symlinks.
prepare_auth_storage(){
	local auth_dir="$HOME/.pi/agent/auth"
	local auth_file="$HOME/.pi/agent/auth.json"
	if [[ -d "$auth_file" ]]; then
		log "WARNING: '${auth_file}' is a directory but pi needs a file. If you bind-mounted a host path that did not exist, remove that directory on the host."
		return 0
	fi
	if [[ -d "$auth_dir" && ! -e "$auth_file" && ! -L "$auth_file" ]]; then
		ln -s "auth/auth.json" "$auth_file"
	fi
}

# The image ships /linux-quick-setup as a git checkout owned by dev. Tolerate a
# different runtime user, and take an optional commit identity from the env.
prepare_git(){
	if ! git config --global --get-all safe.directory 2>/dev/null | grep -qx '/linux-quick-setup'; then
		git config --global --add safe.directory /linux-quick-setup
	fi
	if [[ -n "${GIT_USER_NAME:-}" ]]; then
		git config --global user.name "${GIT_USER_NAME}"
	fi
	if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
		git config --global user.email "${GIT_USER_EMAIL}"
	fi
}

# Make the baked checkout obvious at startup: which ref, and whether the overlay
# left uncommitted changes (i.e. built from a tree that differed from LQS_REF).
log_checkout_state(){
	local repo="/linux-quick-setup"
	[[ -d "${repo}/.git" ]] || return 0
	local ref sha changes
	ref="$(git -C "$repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo '?')"
	[[ "$ref" == "HEAD" ]] && ref="detached"
	sha="$(git -C "$repo" rev-parse --short HEAD 2>/dev/null || echo '?')"
	changes="$(git -C "$repo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
	if [[ "$changes" != "0" ]]; then
		log "linux-quick-setup: ${ref} @ ${sha} (${changes} uncommitted change(s))"
	else
		log "linux-quick-setup: ${ref} @ ${sha} (clean)"
	fi
}

configure_git_credentials(){
	local credentials_file="$HOME/.git-credentials"
	# Mirror install_pi.sh: force github.com through the credential store so a
	# stale helper cannot take precedence over the provided token.
	git config --global --remove-section credential.https://github.com 2>/dev/null || true
	git config --global --replace-all credential.helper ""
	git config --global --add credential.helper store
	git config --global --add credential.https://github.com.helper ""
	git config --global --add credential.https://github.com.helper store

	if [[ -f "$credentials_file" ]]; then
		grep -v 'github.com' "$credentials_file" > "${credentials_file}.tmp" || true
		mv "${credentials_file}.tmp" "$credentials_file"
	fi
	printf 'https://%s:%s@github.com\n' "${PI_GIT_USER:-Glyochi}" "$GITHUB_TOKEN" >> "$credentials_file"
	chmod 600 "$credentials_file"
}

rehydrate(){
	if [[ "$PI_SYNC_REHYDRATE" == "0" ]]; then
		log "Rehydration disabled (PI_SYNC_REHYDRATE=0); using the baked config."
		return 0
	fi
	if [[ ! -d "${PI_AGENT_DIR}/.git" ]]; then
		log "No baked config repo at '${PI_AGENT_DIR}'; skipping rehydration."
		return 0
	fi

	if [[ -n "${GITHUB_TOKEN:-}" ]]; then
		configure_git_credentials
	else
		log "GITHUB_TOKEN is not set; fetching '${PI_SYNC_BRANCH}' anonymously."
	fi

	log "Fetching origin/${PI_SYNC_BRANCH}..."
	if ! GIT_TERMINAL_PROMPT=0 timeout "${PI_SYNC_FETCH_TIMEOUT}" \
		git -C "${PI_AGENT_DIR}" fetch --quiet origin "${PI_SYNC_BRANCH}"; then
		log "WARNING: fetch failed or timed out; keeping the baked config."
		return 0
	fi

	if ! GIT_TERMINAL_PROMPT=0 git -C "${PI_AGENT_DIR}" merge --ff-only FETCH_HEAD; then
		# History diverged (e.g. the branch was rewritten). The remote is
		# authoritative, so discard the baked/local state and take it.
		log "WARNING: cannot fast-forward; resetting the baked config to origin/${PI_SYNC_BRANCH}."
		if ! GIT_TERMINAL_PROMPT=0 git -C "${PI_AGENT_DIR}" reset --hard FETCH_HEAD; then
			log "WARNING: reset failed; keeping the baked config."
			return 0
		fi
	fi

	log "Config updated to $(git -C "${PI_AGENT_DIR}" rev-parse --short HEAD)."
	return 0
}

prepare_auth_storage
prepare_git
log_checkout_state
rehydrate
exec "$@"
