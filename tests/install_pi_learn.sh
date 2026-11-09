#!/usr/bin/env bash
set -Eeuo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
FIXTURE="$(mktemp -d /tmp/pi-learn-installer-test.XXXXXX)"
trap 'rm -rf -- "$FIXTURE"' EXIT
export PI_CODING_AGENT_DIR="${FIXTURE}/agent"
export LEARN_TEST_LOG="${FIXTURE}/commands.log"
mkdir -p "${FIXTURE}/bin"

# No network, real npm install, root access, or host package changes in this test.
printf '%s\n' '#!/usr/bin/env bash' 'set -Eeuo pipefail' \
	'if [[ "${0##*/}" == sudo ]]; then exec "$@"; fi' \
	'printf "%s %s\n" "${0##*/}" "$*" >> "$LEARN_TEST_LOG"' > "${FIXTURE}/bin/stub"
chmod +x "${FIXTURE}/bin/stub"
for name in npm apt-get sudo chromium rsvg-convert; do
	ln -s stub "${FIXTURE}/bin/${name}"
done
export PATH="${FIXTURE}/bin:${PATH}"

bash "${REPO_DIR}/install_pi_learn.sh" --if-present
[[ ! -e "$LEARN_TEST_LOG" ]]
if bash "${REPO_DIR}/install_pi_learn.sh" > "${FIXTURE}/missing.log" 2>&1; then
	printf 'Missing toolkit should fail without --if-present.\n' >&2; exit 1
fi
grep -q 'Sync the Pi config first' "${FIXTURE}/missing.log"

mkdir -p "${PI_CODING_AGENT_DIR}/extensions/learn"
printf '{}\n' > "${PI_CODING_AGENT_DIR}/extensions/learn/package-lock.json"
bash "${REPO_DIR}/install_pi_learn.sh" --system-deps > "${FIXTURE}/install.log" 2>&1
grep -q '^apt-get update$' "$LEARN_TEST_LOG"
grep -q '^apt-get install -y --no-install-recommends chromium librsvg2-bin fonts-dejavu-core$' "$LEARN_TEST_LOG"
grep -q '^npm ci --prefix .* --omit=dev --ignore-scripts --legacy-peer-deps --no-audit --no-fund$' "$LEARN_TEST_LOG"

if bash "${REPO_DIR}/install_pi_learn.sh" --unknown > "${FIXTURE}/invalid.log" 2>&1; then
	printf 'Unknown arguments should fail.\n' >&2; exit 1
else
	[[ $? -eq 2 ]]
fi
printf 'Learning installer checks passed.\n'
