#!/usr/bin/env bash
set -euo pipefail

# ── Colors ─────────────────────────────────────────────────────────
BOLD="\033[1m"
DIM="\033[2m"
CYAN="\033[1;36m"
GREEN="\033[1;32m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

header() { echo -e "\n${CYAN}${BOLD}$1${RESET}"; }
ok() { echo -e "  ${GREEN}✓${RESET}  $1"; }
info() { echo -e "  ${DIM}→${RESET}  $1"; }
warn() { echo -e "  ${YELLOW}⚠${RESET}  $1"; }
err() { echo -e "  ${RED}✗${RESET}  $1"; }
ask() { echo -e -n "\n  ${BOLD}$1${RESET} "; }

NIX=(nix --extra-experimental-features "nix-command flakes")

prompt() {
  local label="$1" default="$2" varname="$3"
  ask "$label [${DIM}$default${RESET}]:"
  read -r input
  if [[ -z "$input" ]]; then
    printf -v "$varname" "%s" "$default"
  else
    printf -v "$varname" "%s" "$input"
  fi
}

confirm() {
  ask "$1 (y/n):"
  read -r ans
  [[ "${ans,,}" == "y" || "${ans,,}" == "yes" ]]
}

# ── Header ─────────────────────────────────────────────────────────
clear
echo -e "${CYAN}${BOLD}"
echo "  ███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗"
echo "  ████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝"
echo "  ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗"
echo "  ██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║"
echo "  ██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║"
echo "  ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
echo -e "${RESET}"
echo -e "  ${DIM}Bootstrap — sets up a new machine from your dotfiles${RESET}\n"

# ── Guards ─────────────────────────────────────────────────────────
if [[ ! -f /etc/NIXOS ]]; then
  err "This script must be run on NixOS."
  exit 1
fi

for cmd in git mkpasswd; do
  if ! command -v "$cmd" &>/dev/null; then
    err "$cmd is required but not found. Run: nix-shell -p $cmd"
    exit 1
  fi
done

# ── Network check ──────────────────────────────────────────────────
header "Checking network…"

if ! ping -c1 github.com &>/dev/null; then
  err "No internet connection (cannot reach github.com)."
  exit 1
fi
ok "Network OK."

# ── EFI check ──────────────────────────────────────────────────────
header "Checking system firmware…"

if [[ -d /sys/firmware/efi ]]; then
  ok "UEFI detected."
else
  err "Legacy BIOS detected. This config requires UEFI."
  exit 1
fi

# ── VM detection ───────────────────────────────────────────────────
VIRT_TYPE="$(systemd-detect-virt 2>/dev/null || echo 'none')"
VIRT_TYPE="${VIRT_TYPE//[$'\t\r\n']/}"
case "$VIRT_TYPE" in
kvm | qemu | vmware | virtualbox | hyperv | xen | lxc | lxc-libvirt | systemd-nspawn)
  IS_VM=true
  ;;
*)
  IS_VM=false
  ;;
esac

# ── Auto-detect ────────────────────────────────────────────────────
header "Auto-detecting system values…"

DETECTED_USER="nixos"
DETECTED_SYSTEM="$("${NIX[@]}" eval --impure --expr 'builtins.currentSystem' --raw 2>/dev/null || echo 'x86_64-linux')"
DETECTED_TIMEZONE="$(timedatectl show --property=Timezone --value 2>/dev/null || echo 'UTC')"
DETECTED_LOCALE="$(locale 2>/dev/null | grep '^LANG=' | cut -d= -f2 | tr -d '"' || echo 'en_US.UTF-8')"
DETECTED_LOCALE="${DETECTED_LOCALE:-en_US.UTF-8}"
DETECTED_KB="$(localectl status 2>/dev/null | grep 'X11 Layout' | awk '{print $NF}' || echo 'us')"
DETECTED_KB="${DETECTED_KB:-us}"
DETECTED_HOSTNAME="$(hostname)"
DETECTED_STATE="$(grep 'system.stateVersion' /etc/nixos/configuration.nix 2>/dev/null | grep -oP '"\K[^"]+' | head -1 || echo '25.11')"
DETECTED_STATE="${DETECTED_STATE:-25.11}"
DETECTED_RAM_KB="$(grep MemTotal /proc/meminfo | awk '{print $2}')"
DETECTED_RAM_GB="$(((DETECTED_RAM_KB + 1048575) / 1048576))"
DETECTED_DISK="$(lsblk -d -n -o NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}' | head -1)"
DETECTED_DISK="${DETECTED_DISK:-/dev/sda}"

ok "system       → $DETECTED_SYSTEM"
ok "timezone     → $DETECTED_TIMEZONE"
ok "locale       → $DETECTED_LOCALE"
ok "keyboard     → $DETECTED_KB"
ok "stateVersion → $DETECTED_STATE"
ok "RAM          → ${DETECTED_RAM_GB}GB"

if [[ "$IS_VM" == "true" ]]; then
  warn "VM detected ($VIRT_TYPE) — lanzaboote skipped, using systemd-boot."
else
  ok "Bare metal detected — lanzaboote + Secure Boot will be configured."
  if ! command -v sbctl &>/dev/null; then
    err "sbctl is required on bare metal but not found. Run: nix-shell -p sbctl"
    exit 1
  fi
fi

echo ""
info "Available disks:"
lsblk -d -o NAME,SIZE,MODEL | grep -v loop | sed 's/^/    /'

# ── Interactive prompts ────────────────────────────────────────────
header "A few things I need from you…"

prompt "Username to configure" "$DETECTED_USER" USERNAME
HOME_DIR="/home/$USERNAME"
prompt "Hostname for this machine" "$DETECTED_HOSTNAME" HOSTNAME
prompt "Your full name" "Your Name" FULLNAME
prompt "Your email" "you@example.com" EMAIL
prompt "Weather city (e.g. New+York)" "New+York" WEATHERCITY
prompt "Dotfiles location on new system" "$HOME_DIR/dotfiles" DOTFILESDIR
prompt "Disk to install to" "$DETECTED_DISK" DISK
prompt "Swap size in GB (>= RAM for hibernate)" "$DETECTED_RAM_GB" SWAP_GB

# ── Temporary login password ───────────────────────────────────────
echo ""
echo -e "  ${YELLOW}${BOLD}Temporary login password${RESET}"
echo -e "  ${DIM}agenix secrets are encrypted to your existing host key and cannot"
echo -e "  be decrypted on a fresh machine. A temporary password is set so you"
echo -e "  can log in. Change it or switch to agenix post-boot.${RESET}\n"

while true; do
  ask "Temporary password for $USERNAME:"
  read -rs TMP_PASSWORD
  echo ""
  ask "Confirm password:"
  read -rs TMP_PASSWORD2
  echo ""
  if [[ "$TMP_PASSWORD" == "$TMP_PASSWORD2" ]]; then
    break
  fi
  echo -e "  ${RED}Passwords do not match, try again.${RESET}"
done

TMP_HASHED_PASSWORD="$(mkpasswd -m sha-512 "$TMP_PASSWORD")"
unset TMP_PASSWORD TMP_PASSWORD2

# ── Wipe warning ───────────────────────────────────────────────────
echo ""
echo -e "  ${RED}${BOLD}╔════════════════════════════════════════════════╗${RESET}"
echo -e "  ${RED}${BOLD}║  WARNING: $DISK WILL BE COMPLETELY WIPED       ║${RESET}"
echo -e "  ${RED}${BOLD}║  ALL DATA ON THIS DISK WILL BE LOST FOREVER    ║${RESET}"
echo -e "  ${RED}${BOLD}╚════════════════════════════════════════════════╝${RESET}"
echo ""

# ── Summary ────────────────────────────────────────────────────────
header "Summary"
echo ""
echo -e "    username      = ${BOLD}$USERNAME${RESET}"
echo -e "    fullName      = ${BOLD}$FULLNAME${RESET}"
echo -e "    email         = ${BOLD}$EMAIL${RESET}"
echo -e "    hostname      = ${BOLD}$HOSTNAME${RESET}"
echo -e "    system        = ${BOLD}$DETECTED_SYSTEM${RESET}"
echo -e "    timezone      = ${BOLD}$DETECTED_TIMEZONE${RESET}"
echo -e "    locale        = ${BOLD}$DETECTED_LOCALE${RESET}"
echo -e "    kbLayout      = ${BOLD}$DETECTED_KB${RESET}"
echo -e "    stateVersion  = ${BOLD}$DETECTED_STATE${RESET}"
echo -e "    weatherCity   = ${BOLD}$WEATHERCITY${RESET}"
echo -e "    dotfilesDir   = ${BOLD}$DOTFILESDIR${RESET}"
echo -e "    disk          = ${RED}${BOLD}$DISK  ← WILL BE WIPED${RESET}"
echo -e "    swap          = ${BOLD}${SWAP_GB}GB swapfile on @swap subvolume${RESET}"
echo -e "    impermanence  = ${BOLD}/ wiped on every boot via btrfs (@blank snapshot)${RESET}"
if [[ "$IS_VM" == "true" ]]; then
  echo -e "    bootloader    = ${YELLOW}${BOLD}systemd-boot (VM — lanzaboote skipped)${RESET}"
else
  echo -e "    bootloader    = ${BOLD}lanzaboote + Secure Boot${RESET}"
fi
echo ""

if ! confirm "Confirm — this will erase $DISK and install NixOS. Proceed?"; then
  warn "Aborted."
  exit 0
fi

# ── Trust current user ─────────────────────────────────────────────
header "Configuring nix trusted user…"

if ! grep -q "trusted-users" /etc/nix/nix.conf 2>/dev/null; then
  echo "trusted-users = root $USERNAME" |
    tee -a /etc/nix/nix.conf >/dev/null
  systemctl restart nix-daemon 2>/dev/null || true
  ok "Added $USERNAME to trusted-users."
else
  ok "Already configured."
fi

# ── Clone repo ─────────────────────────────────────────────────────
header "Cloning dotfiles…"

TMPDIR="/tmp/dotfiles-bootstrap"
rm -rf "$TMPDIR"
git clone https://github.com/BojanKonjevic/dotfiles "$TMPDIR"
ok "Cloned to $TMPDIR."

# ── Write user.nix ─────────────────────────────────────────────────
header "Writing user.nix…"

cat >"$TMPDIR/user.nix" <<USERNIX
{
  # ── Identity ─────────────────────────────────────────────────────
  username      = "$USERNAME";
  fullName      = "$FULLNAME";
  email         = "$EMAIL";
  homeDirectory = "/home/$USERNAME";

  # ── Machine ──────────────────────────────────────────────────────
  hostname     = "$HOSTNAME";
  system       = "$DETECTED_SYSTEM";

  # ── Versions ─────────────────────────────────────────────────────
  stateVersion = "$DETECTED_STATE";

  # ── Locale / Time ────────────────────────────────────────────────
  timezone     = "$DETECTED_TIMEZONE";
  locale       = "$DETECTED_LOCALE";
  kbLayout     = "$DETECTED_KB";

  # ── Paths ────────────────────────────────────────────────────────
  wallpaperDir   = "\$HOME/Pictures/wallpapers";
  screenshotsDir = "\$HOME/Pictures/Screenshots";
  notesFile      = "\$HOME/Documents/notes.txt";
  dotfilesDir    = "$DOTFILESDIR";
  osFlakePath    = "$DOTFILESDIR";
  hmFlakePath    = "$DOTFILESDIR";

  # ── Weather ──────────────────────────────────────────────────────
  weatherCity  = "$WEATHERCITY";

  # ── Hardware ─────────────────────────────────────────────────────
  disk = "$DISK";

  # ── Misc ─────────────────────────────────────────────────────────
  bootstrapMode = true;
}
USERNIX

ok "user.nix written."

# ── Host directory ─────────────────────────────────────────────────
header "Setting up host directory for '$HOSTNAME'…"

HOST_DIR="$TMPDIR/modules/hosts/$HOSTNAME"
mkdir -p "$HOST_DIR"

printf '{ ... }: {}\n' >"$HOST_DIR/hardware.nix"

cat >"$HOST_DIR/default.nix" <<HOSTNIX
{ self, inputs, ... }:
let
  userConfig = import ../../../user.nix;
in {
  flake.nixosConfigurations.\${userConfig.hostname} = inputs.nixpkgs.lib.nixosSystem {
    system = userConfig.system;
    specialArgs = { inherit inputs userConfig self; };
    modules =
      (builtins.attrValues self.nixosModules)
      ++ [
        ./hardware.nix
        ./disko.nix
        ./impermanence.nix
        ./wipe-root.nix
        inputs.disko.nixosModules.disko
        inputs.lanzaboote.nixosModules.lanzaboote
        inputs.impermanence.nixosModules.impermanence
      ]
      ++ (
        let p = ./bootstrap-override.nix; in
        if builtins.pathExists p then [ p ] else []
      );
  };
}
HOSTNIX

ok "default.nix written."

# ── impermanence.nix ───────────────────────────────────────────────
header "Writing impermanence.nix…"

cat >"$HOST_DIR/impermanence.nix" <<'IMPERMANENCE'
{ ... }:
{
  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      { directory = "/etc/ssh";                          mode = "0755"; }
      { directory = "/etc/secureboot";                   mode = "0700"; }
      { directory = "/etc/NetworkManager/system-connections"; mode = "0700"; }
      { directory = "/var/lib/nixos";                    mode = "0755"; }
      { directory = "/var/lib/bluetooth";                mode = "0700"; }
      { directory = "/var/lib/postgresql";               mode = "0700"; }
      { directory = "/var/lib/pipewire";                 mode = "0755"; }
      { directory = "/var/lib/fwupd";                    mode = "0755"; }
      { directory = "/var/lib/libvirt";                  mode = "0755"; }
      { directory = "/var/lib/sudo";                     mode = "0700"; }
      { directory = "/var/cache/tuigreet";               mode = "0755"; }
      { directory = "/var/log/journal";                  mode = "2755"; }
    ];

    files = [
      "/etc/machine-id"
      "/etc/adjtime"
      "/var/lib/systemd/random-seed"
    ];
  };
}
IMPERMANENCE

ok "impermanence.nix written."

# ── wipe-root.nix ─────────────────────────────────────────────────
header "Writing wipe-root initrd module…"

cat >"$HOST_DIR/wipe-root.nix" <<'WIPEROOT'
{ pkgs, config, ... }:
let
  wipe-root-script = pkgs.writeShellApplication {
    name = "wipe-root";
    runtimeInputs = [
      pkgs.btrfs-progs
      pkgs.gnugrep
      pkgs.gawk
      pkgs.coreutils
      pkgs.util-linux
    ];
    text = ''
      echo "wipe-root: Starting root wipe..."

      i=0
      until test -e /dev/disk/by-label/root; do
        echo "wipe-root: Waiting for /dev/disk/by-label/root... ($i)"
        sleep 0.2
        i=$(( i + 1 ))
        if test "$i" -gt 15; then
          echo "wipe-root: Timed out waiting for device"
          exit 1
        fi
      done

      MNT="$(mktemp -d)"
      mount -t btrfs -o subvolid=5 /dev/disk/by-label/root "$MNT"

      if btrfs subvolume list "$MNT" | grep -q ' @blank$'; then
        echo "wipe-root: Deleting @ and all nested subvolumes..."

        NESTED="$(btrfs subvolume list -o "$MNT/@" \
          | awk '{print $NF}' \
          | sort -r)"

        if [ -n "$NESTED" ]; then
          while IFS= read -r sub; do
            echo "wipe-root: Deleting nested subvolume: $sub"
            btrfs subvolume delete "$MNT/$sub"
          done <<< "$NESTED"
        fi

        btrfs subvolume delete "$MNT/@"
        echo "wipe-root: Creating snapshot from @blank..."
        btrfs subvolume snapshot "$MNT/@blank" "$MNT/@"
        echo "wipe-root: Wipe complete."
      else
        echo "wipe-root: @blank not found, skipping wipe." >&2
      fi

      umount "$MNT"
      rmdir "$MNT"
    '';
  };
in {
  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.initrd.systemd.enable = true;

  boot.initrd.systemd.storePaths = [
    "${wipe-root-script}/bin/wipe-root"
    "${pkgs.btrfs-progs}/bin/btrfs"
    "${pkgs.gnugrep}/bin/grep"
    "${pkgs.gawk}/bin/awk"
    "${pkgs.coreutils}/bin/test"
    "${pkgs.coreutils}/bin/sleep"
    "${pkgs.coreutils}/bin/mktemp"
    "${pkgs.coreutils}/bin/rmdir"
    "${pkgs.coreutils}/bin/sort"
    "${pkgs.util-linux}/bin/mount"
    "${pkgs.util-linux}/bin/umount"
  ];

  boot.initrd.systemd.services.wipe-root = {
    description = "Wipe / by restoring @blank btrfs snapshot";
    wantedBy = [ "initrd.target" ];
    after = [ "dev-disk-by\\x2dlabel-root.device" ];
    before = [ "sysroot.mount" "initrd-root-fs.target" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${wipe-root-script}/bin/wipe-root";
    };
  };
}
WIPEROOT

ok "wipe-root.nix written."

# ── bootstrap-override.nix ─────────────────────────────────────────
if [[ "$IS_VM" == "true" ]]; then
  printf '%s\n' \
    '# bootstrap-override.nix — AUTO-GENERATED, delete after post-boot agenix setup.' \
    '#' \
    '# Generated for a VM install — uses systemd-boot instead of lanzaboote.' \
    '#' \
    '# Post-boot steps to restore full agenix:' \
    '#   On your existing machine:' \
    '#     1. Add the new host pubkey to secrets/secrets.nix:' \
    '#          <generated during install>' \
    '#     2. agenix -r -i ~/.ssh/id_ed25519' \
    "#     3. git add -A && git commit -m \"add $HOSTNAME host key\" && git push" \
    '#   On this machine (after git pull):' \
    "#     4. rm $DOTFILESDIR/modules/hosts/$HOSTNAME/bootstrap-override.nix" \
    '#     5. Set bootstrapMode = false in user.nix' \
    '#     6. nr' \
    '{ lib, ... }:' \
    '{' \
    "  users.users.$USERNAME.initialHashedPassword = \"$TMP_HASHED_PASSWORD\";" \
    '  boot.loader.systemd-boot.enable = lib.mkOverride 0 true;' \
    '  boot.loader.efi.canTouchEfiVariables = lib.mkOverride 0 true;' \
    '  boot.lanzaboote.enable = lib.mkOverride 0 false;' \
    '}' \
    >"$HOST_DIR/bootstrap-override.nix"
else
  printf '%s\n' \
    '# bootstrap-override.nix — AUTO-GENERATED, delete after post-boot agenix setup.' \
    '#' \
    '# Post-boot steps to restore full agenix:' \
    '#   On your existing machine:' \
    '#     1. Add the new host pubkey to secrets/secrets.nix:' \
    '#          <generated during install>' \
    '#     2. agenix -r -i ~/.ssh/id_ed25519' \
    "#     3. git add -A && git commit -m \"add $HOSTNAME host key\" && git push" \
    '#   On this machine (after git pull):' \
    "#     4. rm $DOTFILESDIR/modules/hosts/$HOSTNAME/bootstrap-override.nix" \
    '#     5. Set bootstrapMode = false in user.nix' \
    '#     6. nr' \
    '{ ... }:' \
    '{' \
    "  users.users.$USERNAME.initialHashedPassword = \"$TMP_HASHED_PASSWORD\";" \
    '}' \
    >"$HOST_DIR/bootstrap-override.nix"
fi

ok "bootstrap-override.nix written."

# ── Disko config ───────────────────────────────────────────────────
header "Generating disko partition layout…"

cat >"$HOST_DIR/disko.nix" <<DISKO
{
  disko.devices.disk.main = {
    device = "$DISK";
    type = "disk";
    content = {
      type = "gpt";
      partitions = {
        ESP = {
          size = "512M";
          type = "EF00";
          content = {
            type = "filesystem";
            format = "vfat";
            mountpoint = "/boot";
            mountOptions = [ "fmask=0077" "dmask=0077" ];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "btrfs";
            extraArgs = [ "-L" "root" "-f" ];
            subvolumes = {
              "@" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@persist" = {
                mountpoint = "/persist";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              "@swap" = {
                mountpoint = "/swap";
                mountOptions = [ "noatime" ];
              };
              "@snapshots" = {
                mountpoint = "/.snapshots";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
            };
          };
        };
      };
    };
  };
}
DISKO

ok "disko.nix written (btrfs: @, @nix, @home, @persist, @swap, @snapshots; labeled 'root')."

# ── Disko — partition, format, mount ───────────────────────────────
mount -o remount,size=4G /nix/.rw-store 2>/dev/null || true
header "Partitioning and formatting $DISK…"

nix run \
  --extra-experimental-features "nix-command flakes" \
  github:nix-community/disko/latest -- \
  --mode destroy,format,mount \
  "$HOST_DIR/disko.nix"

ok "Disk partitioned, formatted and mounted at /mnt."

# ── @blank snapshot ────────────────────────────────────────────────
header "Creating @blank snapshot for impermanence…"

BTRFS_MNT="/mnt/btrfs-root"
mkdir -p "$BTRFS_MNT"
mount -o subvolid=5 "/dev/disk/by-label/root" "$BTRFS_MNT"

btrfs subvolume snapshot -r "$BTRFS_MNT/@" "$BTRFS_MNT/@blank"
ok "@blank read-only snapshot created."

umount "$BTRFS_MNT"
rmdir "$BTRFS_MNT"

# ── Swapfile on @swap subvolume ────────────────────────────────────
header "Creating swapfile…"

SWAP_DIR="/mnt/swap"
chattr +C "$SWAP_DIR" 2>/dev/null ||
  warn "chattr +C on $SWAP_DIR failed — may already be set, continuing."

SWAPFILE="$SWAP_DIR/swapfile"
fallocate -l "${SWAP_GB}G" "$SWAPFILE" ||
  dd if=/dev/zero of="$SWAPFILE" bs=1M count=$((SWAP_GB * 1024)) status=progress
chmod 600 "$SWAPFILE"
mkswap "$SWAPFILE"
ok "Swapfile created: ${SWAP_GB}G at $SWAPFILE."

# ── /persist directory structure ───────────────────────────────────
header "Preparing /persist…"

mkdir -p /mnt/persist/etc/ssh
mkdir -p /mnt/persist/etc/secureboot
mkdir -p /mnt/persist/etc/NetworkManager/system-connections
mkdir -p /mnt/persist/var/lib/nixos
mkdir -p /mnt/persist/var/lib/bluetooth
mkdir -p /mnt/persist/var/lib/postgresql
mkdir -p /mnt/persist/var/lib/pipewire
mkdir -p /mnt/persist/var/lib/fwupd
mkdir -p /mnt/persist/var/lib/libvirt
mkdir -p /mnt/persist/var/lib/sudo
mkdir -p /mnt/persist/var/cache/tuigreet
mkdir -p /mnt/persist/var/log/journal
mkdir -p /mnt/persist/var/lib/systemd

# Generate a valid machine-id in /persist (this is the persistent one)
{
  tr -d '-' </proc/sys/kernel/random/uuid
  echo
} >/mnt/persist/etc/machine-id
chmod 444 /mnt/persist/etc/machine-id

touch /mnt/persist/etc/adjtime
chmod 700 /mnt/persist/etc/ssh
chmod 700 /mnt/persist/etc/secureboot
chmod 700 /mnt/persist/etc/NetworkManager/system-connections
chmod 755 /mnt/persist/var/lib/nixos
chmod 700 /mnt/persist/var/lib/bluetooth
chmod 700 /mnt/persist/var/lib/postgresql
chmod 755 /mnt/persist/var/lib/pipewire
chmod 755 /mnt/persist/var/lib/fwupd
chmod 755 /mnt/persist/var/lib/libvirt
chmod 700 /mnt/persist/var/lib/sudo
chmod 755 /mnt/persist/var/cache/tuigreet
chmod 2755 /mnt/persist/var/log/journal
chmod 755 /mnt/persist/var/lib/systemd

touch /mnt/persist/var/lib/systemd/random-seed
chmod 600 /mnt/persist/var/lib/systemd/random-seed

ok "/persist directory structure ready."

# ── SSH host key ───────────────────────────────────────────────────
header "Generating SSH host key…"

if [[ ! -f /mnt/persist/etc/ssh/ssh_host_ed25519_key ]]; then
  ssh-keygen -t ed25519 -N "" -f /mnt/persist/etc/ssh/ssh_host_ed25519_key
  chmod 600 /mnt/persist/etc/ssh/ssh_host_ed25519_key
  chmod 644 /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub
  ok "Host key generated."
else
  ok "Host key already exists, reusing."
fi
NEW_HOST_PUBKEY="$(cat /mnt/persist/etc/ssh/ssh_host_ed25519_key.pub)"

sed -i "s|<generated during install>|$NEW_HOST_PUBKEY|g" \
  "$HOST_DIR/bootstrap-override.nix"

# ── Hardware config ────────────────────────────────────────────────
header "Generating hardware configuration…"

nixos-generate-config --root /mnt --no-filesystems
cp /mnt/etc/nixos/hardware-configuration.nix "$HOST_DIR/hardware.nix"
ok "Hardware config written."

# ── Secure Boot keys (bare metal only) ────────────────────────────
if [[ "$IS_VM" == "false" ]]; then
  header "Setting up Secure Boot keys…"

  SBCTL_STATUS="$(sbctl status 2>/dev/null || true)"

  if echo "$SBCTL_STATUS" | grep -q "Setup Mode: Enabled"; then
    info "Firmware is in Setup Mode — creating and enrolling keys."
    sbctl create-keys
    sbctl enroll-keys --microsoft
    ok "Secure Boot keys enrolled."
  elif echo "$SBCTL_STATUS" | grep -q "Secure Boot: disabled"; then
    info "Secure Boot disabled, not in Setup Mode."
    info "Keys will be created now. To enroll after install, enter firmware,"
    info "enable Setup Mode, then run: sbctl enroll-keys --microsoft"
    sbctl create-keys
  else
    warn "Secure Boot status unclear — attempting key creation."
    sbctl create-keys || true
  fi

  if [[ -d /etc/secureboot ]]; then
    cp -r /etc/secureboot/. /mnt/persist/etc/secureboot/
    ok "Secure Boot keys copied to /mnt/persist/etc/secureboot."
  else
    err "sbctl ran but /etc/secureboot not found — lanzaboote will fail."
    err "Enter your firmware, enable Setup Mode, then re-run bootstrap."
    exit 1
  fi
else
  header "Skipping Secure Boot setup (VM)…"
  info "systemd-boot will be used instead of lanzaboote."
fi

# ── Temporary machine‑id for bootloader installation ───────────────
header "Creating temporary machine-id for bootloader..."

mkdir -p /mnt/etc
TMP_MACHINE_ID="$(tr -d '-' </proc/sys/kernel/random/uuid)"
echo "$TMP_MACHINE_ID" >/mnt/etc/machine-id
chmod 444 /mnt/etc/machine-id
ok "Temporary machine-id written."

# ── Install ────────────────────────────────────────────────────────
header "Installing NixOS…"

cd "$TMPDIR"
git add -A
git -c user.email="bootstrap@localhost" \
  -c user.name="bootstrap" \
  commit -m "bootstrap: generated config for $HOSTNAME with impermanence" \
  --allow-empty --quiet

nixos-install \
  --flake "$TMPDIR#$HOSTNAME" \
  --no-root-passwd \
  --option download-buffer-size 134217728

ok "NixOS installed."

# ── Remove temporary machine‑id & adjtime ──────────────────────────
header "Cleaning up temporary files from /etc..."

if [[ -f /mnt/etc/machine-id ]]; then
  rm -f /mnt/etc/machine-id
  ok "Removed /mnt/etc/machine-id"
else
  warn "/mnt/etc/machine-id not found – already removed?"
fi

if [[ -f /mnt/etc/adjtime ]]; then
  rm -f /mnt/etc/adjtime
  ok "Removed /mnt/etc/adjtime"
fi

# Verification
if [[ -e /mnt/etc/machine-id ]] || [[ -e /mnt/etc/adjtime ]]; then
  err "Failed to remove temporary files from /mnt/etc"
  exit 1
fi

ok "Temporary files purged."

# ── Copy dotfiles to installed system ──────────────────────────────
header "Copying dotfiles to new system…"

INSTALL_DOTFILES="/mnt$DOTFILESDIR"
mkdir -p "$(dirname "$INSTALL_DOTFILES")"
cp -r "$TMPDIR/." "$INSTALL_DOTFILES/"
chown -R 1000:100 "/mnt$HOME_DIR"
ok "Dotfiles copied to $INSTALL_DOTFILES."

# ── Done ───────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}  ✓ Installation complete!${RESET}"
echo ""
echo -e "  ${CYAN}${BOLD}New host pubkey (add this to secrets/secrets.nix):${RESET}"
echo -e "  ${BOLD}$NEW_HOST_PUBKEY${RESET}"
echo ""
echo -e "  ${YELLOW}${BOLD}Post-boot steps to restore full agenix:${RESET}"
echo -e "  ${DIM}On your existing machine:${RESET}"
echo -e "    1. Add the pubkey above to secrets/secrets.nix"
echo -e "    2. agenix -r -i ~/.ssh/id_ed25519"
echo -e "    3. git add -A && git commit -m 'add $HOSTNAME host key' && git push"
echo -e "  ${DIM}On this machine (after first boot + git pull):${RESET}"
echo -e "    4. rm $DOTFILESDIR/modules/hosts/$HOSTNAME/bootstrap-override.nix"
echo -e "    5. Set bootstrapMode = false in user.nix"
echo -e "    6. nr"
echo ""
echo -e "  ${CYAN}${BOLD}Impermanence:${RESET}"
echo -e "  ${DIM}/ is wiped on every boot via btrfs @blank snapshot restore."
echo -e "  /home (@home), /nix (@nix), and /persist (@persist) are never wiped."
echo -e "  Persistent state is bind-mounted from /persist on each boot.${RESET}"
echo ""
echo -e "  ${CYAN}${BOLD}Verifying impermanence after first boot:${RESET}"
echo -e "  ${DIM}  journalctl -b -u wipe-root          # confirm wipe ran"
echo -e "    findmnt | grep persist              # confirm bind-mounts active"
echo -e "    touch /test-impermanence && reboot  # file should vanish after reboot${RESET}"
echo ""
if [[ "$IS_VM" == "false" ]]; then
  echo -e "  ${YELLOW}${BOLD}Secure Boot note:${RESET}"
  echo -e "  ${DIM}If keys could not be auto-enrolled, enter your firmware,"
  echo -e "  enable Setup Mode, then run:${RESET}"
  echo -e "    sbctl enroll-keys --microsoft"
  echo ""
fi

if confirm "Reboot now?"; then
  reboot
else
  warn "Remember to reboot before using the system."
fi
