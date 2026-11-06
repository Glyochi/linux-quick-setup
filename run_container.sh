#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail

# Bring the linux-quick-setup container up in the background and open a shell
# inside it.
#
#	bash run_container.sh /projects/app                 # name defaults to app
#	bash run_container.sh /projects/app myapp           # explicit name
#	bash run_container.sh /projects/app myapp nvim      # one-off command
#	bash run_container.sh /projects/app '' tmux new -As main
#
# The container is started detached, so losing the terminal connection (or
# closing the laptop) does not stop it: tmux and any running pi session inside
# keep going, and re-running this script simply re-attaches.
#
# The shell comes from `docker compose exec`, which does not go through docker's
# detach-key proxy, so a lone Ctrl+P reaches the container intact (Pi's model
# cycling, readline history). Only attaching to the container's own stdio --
# `docker compose up` without -d, or `docker attach` -- still holds Ctrl+P as the
# first key of the default ctrl-p,ctrl-q detach sequence.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# docker-compose.yaml stays the single source of truth for the container: the
# mount, the named volumes and image/auth env overrides are read by Compose.
# CODE_DIR and CONTAINER_NAME are set only from positional arguments below.
# Each container gets its own Compose project and Pi volumes,
# so starting a different named container does not replace a running one.
COMPOSE_FILE="${COMPOSE_FILE:-${SCRIPT_DIR}/docker-compose.yaml}"
SERVICE="${SERVICE:-dev}"
# BUILD=1 builds the image locally before starting (compose --build).
BUILD="${BUILD:-0}"

if ! command -v docker >/dev/null 2>&1; then
	print_error "docker is not on PATH. Install Docker, or start the container with 'docker compose up' instead.\n"
	exit 1
fi

if [[ ! -f "$COMPOSE_FILE" ]]; then
	print_error "compose file '${COMPOSE_FILE}' not found. Set COMPOSE_FILE to the docker-compose.yaml to use.\n"
	exit 1
fi

CODE_DIR="${1:-$(dirname -- "$COMPOSE_FILE")}"
CONTAINER_NAME="${2:-}"
if (( $# > 0 )); then shift; fi
if (( $# > 0 )); then shift; fi

if [[ ! -d "$CODE_DIR" ]]; then
	print_error "Path '${CODE_DIR}' is not a directory. Usage: bash run_container.sh [path] [container-name] [command...]\n"
	exit 1
fi

# Resolve relative paths before Compose interprets them relative to its file.
CODE_DIR="$(cd -- "$CODE_DIR" && pwd -P)"
if [[ -z "$CONTAINER_NAME" ]]; then
	CONTAINER_NAME="$(basename -- "$CODE_DIR" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9_.-' '-')"
	CONTAINER_NAME="${CONTAINER_NAME%-}"
fi
if [[ ! "$CONTAINER_NAME" =~ ^[a-zA-Z0-9][a-zA-Z0-9_.-]*$ ]]; then
	print_error "Invalid container name '${CONTAINER_NAME}'. Use a name starting with a letter or digit, followed by letters, digits, underscores, dots or hyphens.\n"
	exit 1
fi
export CODE_DIR CONTAINER_NAME
# Compose project names are lowercase and cannot contain dots. Add a checksum
# when normalizing an explicit name so e.g. Foo/foo or a.b/a_b stay distinct.
project_name="${CONTAINER_NAME,,}"
project_name="${project_name//./_}"
if [[ "$project_name" != "$CONTAINER_NAME" ]]; then
	read -r name_checksum _ <<< "$(printf '%s' "$CONTAINER_NAME" | cksum)"
	project_name="${project_name}-${name_checksum}"
fi
compose=(docker compose -f "$COMPOSE_FILE" -p "$project_name")

print_info "Starting '${SERVICE}' detached (docker compose up -d). Re-run this script to re-attach.\n"
if [[ "$BUILD" == "1" ]]; then
	"${compose[@]}" up -d --build
else
	"${compose[@]}" up -d
fi

if (( $# == 0 )); then
	set -- bash -l
fi

# The image lacks Kitty's terminfo; keep other terminals (including SSH) intact.
exec_options=()
if [[ "${TERM:-}" == "xterm-kitty" ]]; then
	exec_options+=(-e TERM=xterm-256color)
fi

exec "${compose[@]}" exec "${exec_options[@]}" "$SERVICE" "$@"
