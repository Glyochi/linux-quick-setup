#!/usr/bin/env bash
. utils.sh
set -Eeuo pipefail

# Bring the linux-quick-setup container up in the background and open a shell
# inside it.
#
#	bash run_container.sh                    # detached start + login shell
#	bash run_container.sh nvim               # one-off command
#	bash run_container.sh tmux new -As main  # persistent session inside
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
# mount, the named volumes and every supported env override (CODE_DIR, IMAGE,
# IMAGE_TAG, BASE_IMAGE, DEV_UID/DEV_GID, GITHUB_TOKEN, PI_SYNC_*) are read by
# compose itself.
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

if [[ -n "${CODE_DIR:-}" && ! -d "$CODE_DIR" ]]; then
	print_error "CODE_DIR '${CODE_DIR}' is not a directory. Point it at the code you want mounted at /workspace.\n"
	exit 1
fi

compose=(docker compose -f "$COMPOSE_FILE")

print_info "Starting '${SERVICE}' detached (docker compose up -d). Re-run this script to re-attach.\n"
if [[ "$BUILD" == "1" ]]; then
	"${compose[@]}" up -d --build
else
	"${compose[@]}" up -d
fi

if (( $# == 0 )); then
	set -- bash -l
fi

exec "${compose[@]}" exec "$SERVICE" "$@"
