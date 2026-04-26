#!/usr/bin/env bash
set -e

REPO_ROOT="$(git -C "$(dirname "$0")" rev-parse --show-toplevel)"
ISO_DIR="$REPO_ROOT/lib/iso"

ISO_PATH="$REPO_ROOT/result/iso/nixos-custom-installer.iso"
DISK="$ISO_DIR/nixos-test-disk.qcow2"
OVMF_VARS="$ISO_DIR/OVMF_VARS.fd"

OVMF_PREFIX="$(nix-build -E '(import <nixpkgs> {}).OVMF.fd' --no-out-link)"
OVMF_CODE="$OVMF_PREFIX/FV/OVMF_CODE.fd"
OVMF_VARS_TEMPLATE="$OVMF_PREFIX/FV/OVMF_VARS.fd"

QEMU=(
  qemu-system-x86_64
  -enable-kvm
  -m 6500
  -smp 3
  -cpu host
  -machine q35
  -drive "if=pflash,format=raw,readonly=on,file=$OVMF_CODE"
  -drive "if=pflash,format=raw,file=$OVMF_VARS"
  -drive "file=$DISK,format=qcow2,if=virtio"
  -net nic,model=virtio -net user
  -vga virtio
  -display gtk
)

install_mode() {
  echo "→ Install mode — booting from ISO"
  rm -f "$DISK" "$OVMF_VARS"
  qemu-img create -f qcow2 "$DISK" 64G
  cp "$OVMF_VARS_TEMPLATE" "$OVMF_VARS"
  chmod 644 "$OVMF_VARS"

  "${QEMU[@]}" \
    -cdrom "$ISO_PATH" \
    -boot order=d
}

run_mode() {
  echo "→ Run mode — booting installed system"
  "${QEMU[@]}"
}

case "${1:-}" in
install | i) install_mode ;;
run | r) run_mode ;;
*)
  echo "Usage: $0 [install|run]"
  echo "  install  — wipe disk and boot from ISO to run bootstrap"
  echo "  run      — boot the already-installed system"
  exit 1
  ;;
esac
