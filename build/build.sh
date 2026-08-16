#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/work"
ROOTFS="$BUILD_DIR/rootfs"
CONFIG="$ROOT_DIR/build/config"

# shellcheck disable=SC1090
source "$CONFIG"

: "${UBUNTU_RELEASE:=24.04}"
: "${ARCH:=amd64}"
: "${DESKTOP:=xfce}"

mkdir -p "$BUILD_DIR" "$ROOTFS"

if [[ $EUID -ne 0 ]]; then
    echo "Run this build as root (or through sudo)."
    exit 1
fi

command -v debootstrap >/dev/null || {
    echo "debootstrap is required. Install it with: apt install debootstrap"
    exit 1
}

MIRROR="http://archive.ubuntu.com/ubuntu"

echo "==> Bootstrapping Ubuntu $UBUNTU_RELEASE ($ARCH)"
debootstrap --arch="$ARCH" "$UBUNTU_RELEASE" "$ROOTFS" "$MIRROR"

cat > "$ROOTFS/etc/os-release" <<EOF
NAME="RebuiltTux"
PRETTY_NAME="RebuiltTux $DISTRO_VERSION"
ID=rebuilttux
ID_LIKE=ubuntu debian
VERSION_ID="$DISTRO_VERSION"
VERSION="$DISTRO_VERSION"
EOF

echo "==> RebuiltTux base filesystem created at $ROOTFS"
echo "==> Next stage: install packages, configure the desktop, add boot files, and generate the ISO."
