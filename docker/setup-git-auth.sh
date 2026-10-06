#!/usr/bin/env bash
# Set up GitHub credentials inside the container so `git push` over HTTPS works.
#
# Usage:
#   setup-git-auth [--user <github-user>] [--token <token>]
#                  [--name <git-name>] [--email <git-email>] [--check]
#
# Values not passed on the command line are read from the environment
# (GITHUB_USER or PI_GIT_USER, GITHUB_TOKEN, GIT_USER_NAME, GIT_USER_EMAIL) and
# prompted for interactively as a last resort. The token is stored in
# ~/.git-credentials (mode 600) through the git `store` helper; the commit
# identity is optional. Pass --check to verify the token against the GitHub API.
set -Eeuo pipefail

CREDENTIALS_FILE="${HOME}/.git-credentials"

github_user="${GITHUB_USER:-${PI_GIT_USER:-}}"
github_token="${GITHUB_TOKEN:-}"
git_name="${GIT_USER_NAME:-}"
git_email="${GIT_USER_EMAIL:-}"
do_check=0

log(){ printf '[setup-git-auth] %s\n' "$*" >&2; }
die(){ printf 'setup-git-auth: %s\n' "$*" >&2; exit 1; }

usage(){
	cat >&2 <<'EOF'
Usage: setup-git-auth [options]

Store GitHub HTTPS credentials so pushes from inside the container work.

Options:
  -u, --user <github-user>   GitHub account (default: GITHUB_USER, PI_GIT_USER,
                             or the user already in ~/.git-credentials)
  -t, --token <token>        GitHub token (default: GITHUB_TOKEN; prefer the
                             prompt or the env var, since argv is visible to ps)
  -n, --name <git-name>      commit identity name (default: GIT_USER_NAME)
  -e, --email <git-email>    commit identity email (default: GIT_USER_EMAIL)
  -c, --check                verify the token against the GitHub API
  -h, --help                 show this help

The token is written to ~/.git-credentials (mode 600) via the git `store`
helper. Nothing else is persisted.
EOF
}

while [[ $# -gt 0 ]]; do
	case "$1" in
		-u|--user)  [[ $# -ge 2 ]] || die "missing value for $1"; github_user="$2"; shift 2 ;;
		-t|--token) [[ $# -ge 2 ]] || die "missing value for $1"; github_token="$2"; shift 2 ;;
		-n|--name)  [[ $# -ge 2 ]] || die "missing value for $1"; git_name="$2"; shift 2 ;;
		-e|--email) [[ $# -ge 2 ]] || die "missing value for $1"; git_email="$2"; shift 2 ;;
		-c|--check) do_check=1; shift ;;
		-h|--help)  usage; exit 0 ;;
		*) die "unknown argument: $1 (try --help)" ;;
	esac
done

existing_user(){
	sed -n 's#^https://\([^:]*\):[^@]*@github\.com$#\1#p' "$CREDENTIALS_FILE" 2>/dev/null | tail -n1
}

prompt(){
	local label="$1" default="${2:-}" value=""
	if [[ -n "$default" ]]; then
		printf '%s [%s]: ' "$label" "$default" >&2
	else
		printf '%s: ' "$label" >&2
	fi
	IFS= read -r value || true
	printf '%s' "${value:-$default}"
}

prompt_secret(){
	local label="$1" value=""
	printf '%s' "$label" >&2
	IFS= read -rs value || true
	printf '\n' >&2
	printf '%s' "$value"
}

if [[ -z "$github_user" ]]; then
	github_user="$(existing_user || true)"
fi
if [[ -z "$github_user" ]]; then
	[[ -t 0 ]] || die "no GitHub username; pass --user or set GITHUB_USER"
	github_user="$(prompt 'GitHub username')"
fi
[[ -n "$github_user" ]] || die "GitHub username cannot be empty"

if [[ -z "$github_token" ]]; then
	[[ -t 0 ]] || die "no GitHub token; pass --token or set GITHUB_TOKEN"
	github_token="$(prompt_secret 'GitHub token (hidden): ')"
fi
[[ -n "$github_token" ]] || die "GitHub token cannot be empty"

# Fill in the commit identity when it is missing and the user can be prompted.
if [[ -t 0 ]]; then
	if [[ -z "$git_name" ]]; then
		git_name="$(git config --global user.name 2>/dev/null || true)"
		[[ -n "$git_name" ]] || git_name="$(prompt 'Commit name (blank to skip)')"
	fi
	if [[ -z "$git_email" ]]; then
		git_email="$(git config --global user.email 2>/dev/null || true)"
		[[ -n "$git_email" ]] || git_email="$(prompt 'Commit email (blank to skip)')"
	fi
fi

# Mirror the entrypoint: pin github.com to the store helper so a stale helper
# cannot take precedence over the token we are about to write.
configure_git_credentials(){
	git config --global --remove-section credential.https://github.com 2>/dev/null || true
	git config --global --replace-all credential.helper ""
	git config --global --add credential.helper store
	git config --global --add credential.https://github.com.helper ""
	git config --global --add credential.https://github.com.helper store

	if [[ -f "$CREDENTIALS_FILE" ]]; then
		grep -v 'github.com' "$CREDENTIALS_FILE" > "${CREDENTIALS_FILE}.tmp" || true
		mv "${CREDENTIALS_FILE}.tmp" "$CREDENTIALS_FILE"
	fi
	printf 'https://%s:%s@github.com\n' "$github_user" "$github_token" >> "$CREDENTIALS_FILE"
	chmod 600 "$CREDENTIALS_FILE"
}

configure_git_credentials
if [[ -n "$git_name" ]]; then git config --global user.name "$git_name"; fi
if [[ -n "$git_email" ]]; then git config --global user.email "$git_email"; fi

log "stored GitHub credentials for '${github_user}' in ${CREDENTIALS_FILE} (mode 600)"
log "commit identity: $(git config --global user.name 2>/dev/null || echo '(unset)') <$(git config --global user.email 2>/dev/null || echo '(unset)')>"

if [[ "$do_check" == "1" ]]; then
	command -v curl >/dev/null 2>&1 || die "curl is required for --check"
	resp="$(curl -sS --connect-timeout 10 --max-time 20 -D - -u "${github_user}:${github_token}" https://api.github.com/user 2>/dev/null || true)"
	code="$(printf '%s\n' "$resp" | sed -n '1s/^HTTP\/[0-9.]*[[:space:]]*\([0-9]\{3\}\).*/\1/p')"
	if [[ "$code" != "200" ]]; then
		log "WARNING: GitHub rejected the credentials (HTTP ${code:-?})"
		exit 1
	fi
	login="$(printf '%s' "$resp" | sed -n 's/.*"login"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)"
	scopes="$(printf '%s\n' "$resp" | tr -d '\r' | sed -n 's/^[Xx]-[Oo][Aa]uth-[Ss]copes:[[:space:]]*//p' | tail -n1)"
	log "token OK (login: ${login:-$github_user}${scopes:+; scopes: ${scopes}})"
fi
