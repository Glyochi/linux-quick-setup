# syntax=docker/dockerfile:1

# Build the linux-quick-setup environment as a reusable image: pinned Neovim +
# repo config + locked plugins, pinned Pi, a pinned Pi package tree, and the
# pi-config-sync config repo baked at a pinned ref.
#
# Build (the default config repo is public, so no token is required):
#   docker build --build-arg PI_SYNC_REF=<tag-or-sha> -t linux-quick-setup:latest .
# For a private config repo add: --secret id=github_token,env=GITHUB_TOKEN
#
# Re-base onto another glibc image (Debian-based by default), e.g.:
#   docker build --build-arg BASE_IMAGE=python:3.12-slim ...
#
# The linux-quick-setup repo is cloned into /linux-quick-setup so it can be
# edited and pushed from inside the container; mount the code you want to work
# on at /workspace at runtime.

ARG BASE_IMAGE=debian:bookworm-slim
FROM ${BASE_IMAGE}

ARG NEOVIM_VERSION=v0.11.1
ARG TMUX_VERSION=3.6b
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
ARG LQS_REPO=https://github.com/Glyochi/linux-quick-setup.git
ARG LQS_REF=main

ENV DEBIAN_FRONTEND=noninteractive

### UTF-8 locale. tmux only treats a client as UTF-8 when TMUX is set or LC_ALL/LC_CTYPE/LANG
### contains "UTF-8"; otherwise it replaces rounded box corners and Nerd Font icons with "_".
### C.utf8 is built into the image, so no locales package or locale-gen is needed.
ENV LANG=C.UTF-8

### Base packages + pinned Node (official tarball, independent of the base's node)
RUN set -eux; \
	if [ "$(dpkg --print-architecture)" != "amd64" ]; then \
		echo "Only amd64 is supported (Neovim ships an x86_64 tarball)." >&2; \
		exit 1; \
	fi; \
	apt-get update; \
	apt-get install -y --no-install-recommends \
		bash ca-certificates curl git wget tar gzip xz-utils unzip sudo \
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

### Pinned tmux. Debian bookworm ships 3.3a, which predates the extkeys terminal
### feature and extended-keys-format (tmux 3.5), so install the upstream static
### release instead: a single fully static binary, amd64 only, no runtime deps.
### Stay on 3.6b: the 3.7 sorting rework broke `choose-tree` when a session group
### exists (it renders an empty screen and exits on the first key), which is how
### the pi mirror split attaches. Upstream fixed it in 3.8, but tmux-builds has no
### 3.8 static build yet; bump this pin once it does.
RUN set -eux; \
	curl -fsSL "https://github.com/tmux/tmux-builds/releases/download/v${TMUX_VERSION}/tmux-${TMUX_VERSION}-linux-x86_64.tar.gz" \
		-o /tmp/tmux.tar.gz; \
	tar -xzf /tmp/tmux.tar.gz -C /usr/local/bin tmux; \
	rm /tmp/tmux.tar.gz; \
	chmod 0755 /usr/local/bin/tmux; \
	tmux -V

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
	printf 'dev ALL=(ALL) NOPASSWD:ALL\n' > /etc/sudoers.d/dev; \
	chmod 0440 /etc/sudoers.d/dev; \
	visudo --check --file /etc/sudoers.d/dev; \
	mkdir -p /workspace; \
	chown dev:dev /workspace /home/dev

ENV HOME=/home/dev

### linux-quick-setup checkout: clone for real git history and an origin remote,
### then overlay the exact build context so the install matches what is being
### built. .dockerignore keeps the context's .git out, so the clone's .git survives.
RUN git clone "${LQS_REPO}" /linux-quick-setup \
 && git -C /linux-quick-setup checkout "${LQS_REF}"
COPY . /linux-quick-setup/

### Neovim + repo config, reusing install_things.sh in non-interactive mode.
### Running from the checkout makes ~/.config/nvim symlink into it, so edits
### made in the container are live and tracked by git.
WORKDIR /linux-quick-setup
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
		bash install_pi.sh \
 && rm -f /home/dev/.git-credentials

### Seed the pinned Pi package tree from the config repo's settings.json.
### settings.json is only read; Pi resolves the declared packages from this tree.
RUN HOME=/home/dev node <<'NODE'
const fs = require("fs");
const settingsPath = process.env.HOME + "/.pi/agent/settings.json";
const settings = JSON.parse(fs.readFileSync(settingsPath, "utf8"));
const dependencies = {};
for (const entry of settings.packages || []) {
	const source = typeof entry === "string" ? entry : entry && entry.source;
	if (typeof source !== "string" || !source.startsWith("npm:")) {
		if (source) console.error("skipping non-npm package: " + source);
		continue;
	}
	const rest = source.slice(4);
	const at = rest.lastIndexOf("@");
	const name = at > 0 ? rest.slice(0, at) : rest;
	const version = at > 0 ? rest.slice(at + 1) : "*";
	if (name) dependencies[name] = version;
}
const npmDir = process.env.HOME + "/.pi/agent/npm";
fs.mkdirSync(npmDir, { recursive: true });
fs.writeFileSync(npmDir + "/package.json", JSON.stringify({ name: "pi-extensions", private: true, dependencies }, null, 2) + "\n");
console.log("seeded Pi packages: " + JSON.stringify(dependencies));
NODE
RUN HOME=/home/dev npm install --prefix /home/dev/.pi/agent/npm --legacy-peer-deps \
 && HOME=/home/dev npm cache clean --force

### Runtime
COPY docker/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
COPY docker/setup-git-auth.sh /usr/local/bin/setup-git-auth
# /etc/profile resets PATH for login shells, so re-add the toolchain there too.
RUN chmod 0755 /usr/local/bin/docker-entrypoint.sh /usr/local/bin/setup-git-auth \
 && printf 'export PATH="/usr/local/nvim-linux-x86_64/bin:/opt/node/bin:$PATH"\nalias vim=nvim\nalias vi=nvim\n' > /etc/profile.d/linux-quick-setup.sh \
 && chmod 0644 /etc/profile.d/linux-quick-setup.sh \
 && printf '\n# linux-quick-setup: use nvim for vim/vi\nalias vim=nvim\nalias vi=nvim\n' >> /home/dev/.bashrc \
 && mkdir -p /home/dev/.pi/agent/sessions /home/dev/.pi/agent/state /home/dev/.pi/agent/auth \
 && chown -R dev:dev /home/dev /linux-quick-setup

ENV PI_SYNC_REPO="${PI_SYNC_REPO}" \
	PI_SYNC_BRANCH="${PI_SYNC_BRANCH}"

WORKDIR /workspace
USER dev
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["bash", "-l"]
