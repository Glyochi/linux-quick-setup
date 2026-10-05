# syntax=docker/dockerfile:1

# Build the linux-quick-setup environment as a reusable image: pinned Neovim +
# repo config + locked plugins, pinned Pi, a pinned Pi package tree, and the
# private pi-config-sync config repo baked at a pinned ref.
#
# Build (the default config repo is public, so no token is required):
#   docker build --build-arg PI_SYNC_REF=<tag-or-sha> -t linux-quick-setup:latest .
# For a private config repo add: --secret id=github_token,env=GITHUB_TOKEN
#
# Re-base onto another glibc image (Debian-based by default), e.g.:
#   docker build --build-arg BASE_IMAGE=python:3.12-slim ...
#
# The code repo is expected to be mounted at /workspace at runtime. Only the
# toolchain and config are baked in; the repository itself is not copied.

ARG BASE_IMAGE=debian:bookworm-slim
FROM ${BASE_IMAGE}

ARG NEOVIM_VERSION=v0.11.1
ARG NODE_VERSION=22.23.3
ARG PI_VERSION=1.0.0
ARG BASEDPYRIGHT_VERSION=1.40.2
ARG BLACK_VERSION=26.10.0
ARG PI_SYNC_REPO=https://github.com/Glyochi/pi-config-sync.git
ARG PI_SYNC_REF=main
ARG PI_SYNC_BRANCH=main
ARG PI_GIT_USER=Glyochi
ARG DEV_UID=1000
ARG DEV_GID=1000

ENV DEBIAN_FRONTEND=noninteractive

### Base packages + pinned Node (official tarball, independent of the base's node)
RUN set -eux; \
	if [ "$(dpkg --print-architecture)" != "amd64" ]; then \
		echo "Only amd64 is supported (Neovim ships an x86_64 tarball)." >&2; \
		exit 1; \
	fi; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		bash ca-certificates curl git wget tar gzip xz-utils unzip \
		tree ripgrep fd-find build-essential python3 python3-pip; \
	if fdfind_path="$(command -v fdfind)"; then ln -sf "$fdfind_path" /usr/local/bin/fd; fi; \
	rm -rf /var/lib/apt/lists/*; \
	curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-x64.tar.xz" -o /tmp/node.tar.xz; \
	mkdir -p /opt/node; \
	tar -xJf /tmp/node.tar.xz -C /opt/node --strip-components=1; \
	rm /tmp/node.tar.xz; \
	export PATH="/opt/node/bin:$PATH"; \
	node --version; \
	npm --version

ENV PATH="/opt/node/bin:${PATH}"

### Non-root dev user (replaces any base user already holding the target uid/gid)
RUN set -eux; \
	if getent passwd "${DEV_UID}" >/dev/null; then \
		userdel -r "$(getent passwd "${DEV_UID}" | cut -d: -f1)" || true; \
	fi; \
	if getent group "${DEV_GID}" >/dev/null; then \
		groupdel "$(getent group "${DEV_GID}" | cut -d: -f1)" || true; \
	fi; \
	groupadd --gid "${DEV_GID}" dev; \
	useradd --uid "${DEV_UID}" --gid "${DEV_GID}" --create-home --shell /bin/bash dev; \
	mkdir -p /workspace; \
	chown dev:dev /workspace /home/dev

ENV HOME=/home/dev

### Neovim + repo config, reusing install_things.sh in non-interactive mode
COPY utils.sh back_bone.sh install_things.sh install_pi.sh /opt/linux-quick-setup/
COPY neovim/ /opt/linux-quick-setup/neovim/
WORKDIR /opt/linux-quick-setup
RUN HOME=/home/dev SUDO="" PI_NONINTERACTIVE=1 NEOVIM_VERSION="${NEOVIM_VERSION}" \
		bash install_things.sh

ENV PATH="/usr/local/nvim-linux-x86_64/bin:${PATH}"

### Prime locked plugins, treesitter parsers and plugin build steps (e.g. `npm i`)
RUN HOME=/home/dev nvim --headless "+Lazy! restore" +qa

### Pinned Pi, language server and formatter tooling
RUN npm install -g --ignore-scripts "@earendil-works/pi-coding-agent@${PI_VERSION}" \
 && npm install -g "basedpyright@${BASEDPYRIGHT_VERSION}" \
 && npm cache clean --force
RUN python3 -m pip install --no-cache-dir --break-system-packages "black==${BLACK_VERSION}"

### Bake the config repo at a pinned ref.
# The default repo is public, so no secret is needed. Pass
# `--secret id=github_token,env=GITHUB_TOKEN` for a private repo; the credential
# file install_pi.sh writes is removed in the same layer, so it is never persisted.
RUN --mount=type=secret,id=github_token \
	if [ -f /run/secrets/github_token ]; then export GITHUB_TOKEN="$(cat /run/secrets/github_token)"; fi; \
	HOME=/home/dev \
	PI_SYNC_REPO="${PI_SYNC_REPO}" \
	PI_SYNC_REF="${PI_SYNC_REF}" \
	PI_GIT_USER="${PI_GIT_USER}" \
	PI_SYNC_SKIP_INSTALL=1 \
		bash install_pi.sh \
 && rm -f /home/dev/.git-credentials

### Seed the pinned Pi package tree without mutating the config repo settings.json
COPY docker/pi-packages.json /opt/linux-quick-setup/docker/pi-packages.json
RUN mkdir -p /home/dev/.pi/agent/npm \
 && cp /opt/linux-quick-setup/docker/pi-packages.json /home/dev/.pi/agent/npm/package.json \
 && HOME=/home/dev npm install --prefix /home/dev/.pi/agent/npm --legacy-peer-deps \
 && HOME=/home/dev npm cache clean --force

### Runtime
COPY docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
# /etc/profile resets PATH for login shells, so re-add the toolchain there too.
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh \
 && printf 'export PATH="/usr/local/nvim-linux-x86_64/bin:/opt/node/bin:$PATH"\n' > /etc/profile.d/linux-quick-setup.sh \
 && chmod 0644 /etc/profile.d/linux-quick-setup.sh \
 && mkdir -p /home/dev/.pi/agent/sessions /home/dev/.pi/agent/state /home/dev/.pi/agent/auth \
 && chown -R dev:dev /home/dev /opt/linux-quick-setup

ENV PI_SYNC_REPO="${PI_SYNC_REPO}" \
	PI_SYNC_BRANCH="${PI_SYNC_BRANCH}"

WORKDIR /workspace
USER dev
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash", "-l"]
