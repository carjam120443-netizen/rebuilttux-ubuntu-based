#!/usr/bin/env bash
set -euo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/work"
ROOTFS="$BUILD_DIR/rootfs"
ISO_DIR="$BUILD_DIR/iso"
CONFIG="$ROOT_DIR/build/config"
source "$CONFIG"
: "${UBUNTU_RELEASE:=24.04}"; : "${ARCH:=amd64}"; : "${DESKTOP:=xfce}"
[[ $EUID -eq 0 ]] || { echo "Run with sudo/root."; exit 1; }
for c in debootstrap mksquashfs grub-mkrescue xorriso; do command -v "$c" >/dev/null || { echo "Missing required tool: $c"; exit 1; }; done
mkdir -p "$BUILD_DIR" "$ROOTFS" "$ISO_DIR/boot/grub" "$ISO_DIR/casper"
MIRROR="http://archive.ubuntu.com/ubuntu"

echo "==> 1/6 Bootstrap Ubuntu $UBUNTU_RELEASE"
if [[ ! -e "$ROOTFS/etc/os-release" ]]; then debootstrap --arch="$ARCH" "$UBUNTU_RELEASE" "$ROOTFS" "$MIRROR"; fi
mount --bind /dev "$ROOTFS/dev"; mount --bind /dev/pts "$ROOTFS/dev/pts"; mount -t proc proc "$ROOTFS/proc"; mount -t sysfs sysfs "$ROOTFS/sys"; mount -t tmpfs tmpfs "$ROOTFS/run"
cleanup(){ umount -lf "$ROOTFS/run" 2>/dev/null || true; umount -lf "$ROOTFS/sys" 2>/dev/null || true; umount -lf "$ROOTFS/proc" 2>/dev/null || true; umount -lf "$ROOTFS/dev/pts" 2>/dev/null || true; umount -lf "$ROOTFS/dev" 2>/dev/null || true; }; trap cleanup EXIT
cp -L /etc/resolv.conf "$ROOTFS/etc/resolv.conf" || true

chroot "$ROOTFS" /bin/bash <<'CHROOT'
set -e
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y linux-image-generic systemd-sysv sudo network-manager dbus xorg xfce4 lightdm lightdm-gtk-greeter casper initramfs-tools grub-pc grub-efi-amd64-signed shim-signed
apt-get clean
rm -rf /var/lib/apt/lists/*
cat > /etc/os-release <<'EOF'
NAME="RebuiltTux"
PRETTY_NAME="RebuiltTux Ubuntu Based"
ID=rebuilttux
ID_LIKE="ubuntu debian"
VERSION_ID="0.1"
VERSION="0.1 (Ubuntu Based)"
HOME_URL="https://github.com/carjam120443-netizen/rebuilttux-ubuntu-based"
EOF
echo rebuilttux > /etc/hostname
systemctl enable NetworkManager lightdm || true
update-initramfs -c -k all || update-initramfs -u -k all
CHROOT

echo "==> 2/6 Add RebuiltTux filesystem files"
if [[ -d "$ROOT_DIR/filesystem" ]]; then cp -a "$ROOT_DIR/filesystem/." "$ROOTFS/"; fi

echo "==> 3/6 Build SquashFS"
rm -f "$ISO_DIR/casper/filesystem.squashfs"
mksquashfs "$ROOTFS" "$ISO_DIR/casper/filesystem.squashfs" -comp xz -noappend

echo "==> 4/6 Copy kernel and initramfs"
KERNEL=$(find "$ROOTFS/boot" -maxdepth 1 -name 'vmlinuz-*' | sort | tail -1)
INITRD=$(find "$ROOTFS/boot" -maxdepth 1 -name 'initrd.img-*' | sort | tail -1)
cp "$KERNEL" "$ISO_DIR/casper/vmlinuz"
cp "$INITRD" "$ISO_DIR/casper/initrd"

echo "==> 5/6 Create GRUB boot configuration"
cat > "$ISO_DIR/boot/grub/grub.cfg" <<'EOF'
set timeout=5
set default=0
menuentry "RebuiltTux" {
    linux /casper/vmlinuz boot=casper quiet splash
    initrd /casper/initrd
}
menuentry "RebuiltTux (safe graphics)" {
    linux /casper/vmlinuz boot=casper nomodeset
    initrd /casper/initrd
}
EOF
cat > "$ISO_DIR/README" <<'EOF'
RebuiltTux Ubuntu Based live ISO
Boot with the default RebuiltTux entry.
EOF

echo "==> 6/6 Generate ISO"
mkdir -p "$ROOT_DIR/output"
rm -f "$ROOT_DIR/output/RebuiltTux-${UBUNTU_RELEASE}-${ARCH}.iso"
grub-mkrescue -o "$ROOT_DIR/output/RebuiltTux-${UBUNTU_RELEASE}-${ARCH}.iso" "$ISO_DIR"
echo "==> DONE: $ROOT_DIR/output/RebuiltTux-${UBUNTU_RELEASE}-${ARCH}.iso"
