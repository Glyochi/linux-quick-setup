#!/usr/bin/env bash
set -Eeuo pipefail

# Runtime dependencies for the opt-in toolkit in the separately synced Pi config.
PI_AGENT_DIR="${PI_CODING_AGENT_DIR:-$HOME/.pi/agent}"
LEARN_DIR="${PI_AGENT_DIR}/extensions/learn"
install_system=0
if_present=0

for arg in "$@"; do
	case "$arg" in
		--system-deps) install_system=1 ;;
		--if-present) if_present=1 ;;
		*) printf 'Usage: bash install_pi_learn.sh [--system-deps] [--if-present]\n' >&2; exit 2 ;;
	esac
done

if [[ ! -f "${LEARN_DIR}/package-lock.json" ]]; then
	if (( if_present )); then exit 0; fi
	printf 'Learning toolkit is not configured at %s. Sync the Pi config first.\n' "$LEARN_DIR" >&2
	exit 1
fi
if ! command -v npm >/dev/null 2>&1 || ! command -v node >/dev/null 2>&1; then
	printf 'npm and Node.js 22.19+ are required to install the locked learning renderers.\n' >&2
	exit 1
fi
if ! node -e 'const [major, minor] = process.versions.node.split(".").map(Number); process.exit(major > 22 || (major === 22 && minor >= 19) ? 0 : 1)'; then
	printf 'The learning toolkit requires Node.js 22.19+ (matching current Pi).\n' >&2
	exit 1
fi

if (( install_system )); then
	if ! command -v apt-get >/dev/null 2>&1; then
		printf 'Automatic system setup supports Debian/Ubuntu. Install Chromium, rsvg-convert, and fonts manually, then rerun without --system-deps.\n' >&2
		exit 1
	fi
	apt_command=(apt-get)
	if (( EUID != 0 )); then apt_command=(sudo apt-get); fi
	"${apt_command[@]}" update
	"${apt_command[@]}" install -y --no-install-recommends chromium librsvg2-bin fonts-dejavu-core
fi

# Puppeteer uses system Chromium; never download a second browser or run lifecycle scripts.
PUPPETEER_SKIP_DOWNLOAD=1 npm ci --prefix "$LEARN_DIR" \
	--omit=dev --ignore-scripts --legacy-peer-deps --no-audit --no-fund
printf 'Learning dependencies installed. Restart Pi or /reload, then run /learn-doctor.\n'
if ! command -v rsvg-convert >/dev/null 2>&1; then
	printf 'SVG renderer missing: rerun with --system-deps, or install librsvg2-bin manually.\n' >&2
fi
if [[ -z "${PI_LEARN_CHROME:-}" ]] && ! command -v chromium >/dev/null 2>&1 \
	&& ! command -v chromium-browser >/dev/null 2>&1 && ! command -v google-chrome >/dev/null 2>&1 \
	&& ! command -v google-chrome-stable >/dev/null 2>&1; then
	printf 'Chromium missing: rerun with --system-deps, or set PI_LEARN_CHROME to your browser executable.\n' >&2
fi
