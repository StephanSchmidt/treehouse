#!/bin/sh
set -eu

# human CLI devcontainer Feature installer
# Reads VERSION from the devcontainer Feature option (env var)

REPO="StephanSchmidt/human"
VERSION="${VERSION:-latest}"
PROXY="${PROXY:-false}"

fail() { printf 'Error: %s\n' "$1" >&2; exit 1; }

# --- ensure dependencies -----------------------------------------------------
if ! command -v curl >/dev/null 2>&1; then
    apt-get update -y && apt-get install -y --no-install-recommends curl ca-certificates
fi

# --- detect arch --------------------------------------------------------------
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64)        ARCH=amd64 ;;
  aarch64|arm64) ARCH=arm64 ;;
  *)             fail "unsupported architecture: $ARCH" ;;
esac

# --- resolve version ----------------------------------------------------------
if [ "$VERSION" = "latest" ]; then
    printf 'Fetching latest release...\n'
    VERSION="$(curl -sSfL "https://api.github.com/repos/${REPO}/releases/latest" \
      | grep '"tag_name"' | head -1 | sed 's/.*"tag_name": *"//;s/".*//')"
    [ -z "$VERSION" ] && fail "could not determine latest version"
fi

# strip leading 'v' for archive name, ensure VERSION has leading 'v' for URL
case "$VERSION" in
  v*) VERSION_NUM="${VERSION#v}" ;;
  *)  VERSION_NUM="$VERSION"; VERSION="v${VERSION}" ;;
esac
printf 'Installing human %s\n' "$VERSION"

# --- build download URLs ------------------------------------------------------
ARCHIVE="human_${VERSION_NUM}_linux_${ARCH}.tar.gz"
BASE_URL="https://github.com/${REPO}/releases/download/${VERSION}"
ARCHIVE_URL="${BASE_URL}/${ARCHIVE}"
CHECKSUMS_URL="${BASE_URL}/checksums.txt"

# --- download into temp dir ---------------------------------------------------
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

printf 'Downloading %s...\n' "$ARCHIVE"
curl -sSfL -o "${TMPDIR}/${ARCHIVE}" "$ARCHIVE_URL"
curl -sSfL -o "${TMPDIR}/checksums.txt" "$CHECKSUMS_URL"

# --- verify checksum ----------------------------------------------------------
printf 'Verifying checksum...\n'
EXPECTED="$(grep "${ARCHIVE}" "${TMPDIR}/checksums.txt" | awk '{print $1}')"
[ -z "$EXPECTED" ] && fail "checksum not found for ${ARCHIVE}"

ACTUAL="$(sha256sum "${TMPDIR}/${ARCHIVE}" | awk '{print $1}')"
[ "$EXPECTED" != "$ACTUAL" ] && fail "checksum mismatch: expected ${EXPECTED}, got ${ACTUAL}"

# --- extract and install ------------------------------------------------------
printf 'Extracting...\n'
tar -xzf "${TMPDIR}/${ARCHIVE}" -C "$TMPDIR"

install -d /usr/local/bin
install "${TMPDIR}/human" /usr/local/bin/human
ln -sf /usr/local/bin/human /usr/local/bin/human-browser
printf 'human-browser symlink created\n'

printf 'human %s installed to /usr/local/bin/human\n' "$VERSION"

# --- optional HTTPS proxy setup ----------------------------------------------
if [ "$PROXY" = "true" ]; then
    printf 'Installing HTTPS proxy support...\n'

    # Install iptables if missing.
    if ! command -v iptables >/dev/null 2>&1; then
        apt-get update -y && apt-get install -y --no-install-recommends iptables
    fi

    # Drop a script that reads HUMAN_PROXY_ADDR at runtime.
    cat > /usr/local/bin/human-proxy-setup <<'SCRIPT'
#!/bin/sh
set -eu

ADDR="${HUMAN_PROXY_ADDR:-}"
if [ -z "$ADDR" ]; then
    printf 'HUMAN_PROXY_ADDR is not set, skipping proxy setup.\n'
    exit 0
fi

HOST="${ADDR%:*}"

# DNAT: redirect outbound HTTPS to the proxy (idempotent).
iptables -t nat -C OUTPUT -p tcp --dport 443 \
    ! -d "$HOST" \
    -j DNAT --to-destination "$ADDR" 2>/dev/null \
|| iptables -t nat -A OUTPUT -p tcp --dport 443 \
    ! -d "$HOST" \
    -j DNAT --to-destination "$ADDR"

# MASQUERADE: ensure return packets route correctly.
iptables -t nat -C POSTROUTING -j MASQUERADE 2>/dev/null \
|| iptables -t nat -A POSTROUTING -j MASQUERADE

printf 'HTTPS proxy redirect active → %s\n' "$ADDR"
SCRIPT
    chmod +x /usr/local/bin/human-proxy-setup

    printf 'Proxy support installed. Set HUMAN_PROXY_ADDR and run "human-proxy-setup" at container start.\n'
fi
