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
if [[ "$VIRT_TYPE" != "none" ]]; then
  IS_VM=true
else
  IS_VM=false
fi

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
# Generated into the host directory. Home is handled entirely by
# home-manager and lives on @home (never wiped), so nothing here
# touches /home. This only covers system-level state.
header "Writing impermanence.nix…"

cat >"$HOST_DIR/impermanence.nix" <<'IMPERMANENCE'
{ ... }:
{
  # disko doesn't expose neededForBoot on btrfs subvolumes, so set it here.
  # The impermanence module asserts this is true before setting up bind-mounts.
  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      { directory = "/etc/ssh";             mode = "0755"; }
      { directory = "/etc/secureboot";      mode = "0700"; }
      { directory = "/etc/NetworkManager/system-connections"; mode = "0700"; }
      { directory = "/var/lib/nixos";       mode = "0755"; }
      { directory = "/var/lib/systemd";     mode = "0755"; }
      { directory = "/var/lib/bluetooth";   mode = "0700"; }
      { directory = "/var/lib/postgresql";  mode = "0700"; }
      { directory = "/var/lib/pipewire";    mode = "0755"; }
      { directory = "/var/lib/fwupd";       mode = "0755"; }
      { directory = "/var/lib/libvirt";     mode = "0755"; }
      { directory = "/var/log/journal";     mode = "2755"; }
    ];

    files = [
      "/etc/machine-id"
      "/etc/adjtime"
    ];
  };
}
IMPERMANENCE

ok "impermanence.nix written."

# ── bootstrap-override.nix ─────────────────────────────────────────
if [[ "$IS_VM" == "true" ]]; then
  cat >"$HOST_DIR/bootstrap-override.nix" <<OVERRIDE
# bootstrap-override.nix — AUTO-GENERATED, delete after post-boot agenix setup.
#
# Generated for a VM install — uses systemd-boot instead of lanzaboote.
#
# Post-boot steps to restore full agenix:
#   On your existing machine:
#     1. Add the new host pubkey to secrets/secrets.nix:
#          <generated during install>
#     2. agenix -r -i ~/.ssh/id_ed25519
#     3. git add -A && git commit -m "add $HOSTNAME host key" && git push
#   On this machine (after git pull):
#     4. rm $DOTFILESDIR/modules/hosts/$HOSTNAME/bootstrap-override.nix
#     5. Set bootstrapMode = false in user.nix
#     6. nr
{ lib, ... }:
{
  users.users.$USERNAME.initialHashedPassword = "$TMP_HASHED_PASSWORD";
  boot.loader.systemd-boot.enable = lib.mkOverride 0 true;
  boot.loader.efi.canTouchEfiVariables = lib.mkOverride 0 true;
  boot.lanzaboote.enable = lib.mkOverride 0 false;
}
OVERRIDE
else
  cat >"$HOST_DIR/bootstrap-override.nix" <<OVERRIDE
# bootstrap-override.nix — AUTO-GENERATED, delete after post-boot agenix setup.
#
# Post-boot steps to restore full agenix:
#   On your existing machine:
#     1. Add the new host pubkey to secrets/secrets.nix:
#          <generated during install>
#     2. agenix -r -i ~/.ssh/id_ed25519
#     3. git add -A && git commit -m "add $HOSTNAME host key" && git push
#   On this machine (after git pull):
#     4. rm $DOTFILESDIR/modules/hosts/$HOSTNAME/bootstrap-override.nix
#     5. Set bootstrapMode = false in user.nix
#     6. nr
{ ... }:
{
  users.users.$USERNAME.initialHashedPassword = "$TMP_HASHED_PASSWORD";
}
OVERRIDE
fi

ok "bootstrap-override.nix written."

# ── Disko config ───────────────────────────────────────────────────
header "Generating disko partition layout…"

SWAP_SIZE="${SWAP_GB}G"

# Determine partition suffix for nvme/mmcblk vs plain block devices
if [[ "$DISK" == *"nvme"* ]] || [[ "$DISK" == *"mmcblk"* ]]; then
  PART_SEP="p"
else
  PART_SEP=""
fi

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
            # -L root  → label used by the initrd wipe-root service
            #            (/dev/disk/by-label/root)
            # -f       → force-format even if a filesystem already exists
            extraArgs = [ "-L" "root" "-f" ];
            subvolumes = {
              # Wiped on every boot by the wipe-root initrd service.
              # @blank is a read-only snapshot of this taken after first format.
              "@" = {
                mountpoint = "/";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              # Nix store — never wiped.
              "@nix" = {
                mountpoint = "/nix";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              # Home — never wiped; home-manager manages its contents.
              "@home" = {
                mountpoint = "/home";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              # Explicit persistent state — bind-mounted by impermanence.nix.
              "@persist" = {
                mountpoint = "/persist";
                mountOptions = [ "compress=zstd" "noatime" ];
              };
              # Swapfile lives here; CoW disabled by bootstrap (chattr +C).
              "@swap" = {
                mountpoint = "/swap";
                mountOptions = [ "noatime" ];
              };
              # Reserved for future snapshots.
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
# Take a read-only snapshot of the empty @ subvolume right after
# formatting. The initrd wipe-root service will restore this snapshot
# on every subsequent boot, giving us a clean / each time.
header "Creating @blank snapshot for impermanence…"

# Mount the raw btrfs volume (no subvolume) so we can work with subvols directly.
BTRFS_MNT="/mnt/btrfs-root"
mkdir -p "$BTRFS_MNT"
mount -o subvolid=5 "/dev/disk/by-label/root" "$BTRFS_MNT"

# @ must exist and be empty at this point (disko just created it).
btrfs subvolume snapshot -r "$BTRFS_MNT/@" "$BTRFS_MNT/@blank"
ok "@blank read-only snapshot created."

umount "$BTRFS_MNT"
rmdir "$BTRFS_MNT"

# ── Wipe-root initrd service ───────────────────────────────────────
# Written into core.nix equivalent via a NixOS module in the host dir.
# We inject it here as a file that default.nix already imports.
header "Writing wipe-root initrd module…"

cat >"$HOST_DIR/wipe-root.nix" <<'WIPEROOT'
{ pkgs, ... }:
{
  boot.initrd.supportedFilesystems = [ "btrfs" ];
  boot.initrd.systemd.enable = true;

  boot.initrd.systemd.services.wipe-root = {
    description = "Wipe / by restoring @blank btrfs snapshot";
    wantedBy = [ "initrd.target" ];
    after    = [ "dev-disk-by\\x2dlabel-root.device" ];
    before   = [ "sysroot.mount" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type      = "oneshot";
      ExecStart = pkgs.writeShellScript "wipe-root" ''
        set -euo pipefail
        MNT="$(mktemp -d)"
        mount -o subvolid=5 /dev/disk/by-label/root "$MNT"
        if btrfs subvolume list "$MNT" | grep -q ' @blank$'; then
          btrfs subvolume delete "$MNT/@"
          btrfs subvolume snapshot "$MNT/@blank" "$MNT/@"
        else
          echo "wipe-root: @blank not found, skipping." >&2
        fi
        umount "$MNT"
        rmdir  "$MNT"
      '';
    };
  };
}
WIPEROOT

# Update default.nix to also import wipe-root.nix
sed -i 's|./impermanence.nix|./impermanence.nix\n        ./wipe-root.nix|' "$HOST_DIR/default.nix"

ok "wipe-root.nix written and imported."

# ── Swapfile on @swap subvolume ────────────────────────────────────
header "Creating swapfile…"

# BTRFS swapfiles require CoW to be disabled on the file (not just the
# subvolume). We set it on the subvolume directory first so new files
# inherit the flag, then create the swapfile.
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
# Pre-create all directories that impermanence.nix will bind-mount.
# Without this the bind-mounts fail on first boot.
header "Preparing /persist…"

mkdir -p /mnt/persist/etc/ssh
mkdir -p /mnt/persist/etc/secureboot
mkdir -p /mnt/persist/etc/NetworkManager/system-connections
mkdir -p /mnt/persist/var/lib/nixos
mkdir -p /mnt/persist/var/lib/systemd
mkdir -p /mnt/persist/var/lib/bluetooth
mkdir -p /mnt/persist/var/lib/postgresql
mkdir -p /mnt/persist/var/lib/pipewire
mkdir -p /mnt/persist/var/lib/fwupd
mkdir -p /mnt/persist/var/lib/libvirt
mkdir -p /mnt/persist/var/log/journal

# machine-id must be a valid 32-char hex string — systemd-boot reads it
# during nixos-install and crashes with IndexError on an empty file.
systemd-machine-id-setup --root=/mnt 2>/dev/null ||
  printf '%s\n' "$(cat /proc/sys/kernel/random/uuid | tr -d '-')" >/mnt/etc/machine-id
cp /mnt/etc/machine-id /mnt/persist/etc/machine-id
touch /mnt/persist/etc/adjtime

# Correct permissions upfront so impermanence bind-mounts start clean.
chmod 700 /mnt/persist/etc/ssh
chmod 700 /mnt/persist/etc/secureboot
chmod 700 /mnt/persist/etc/NetworkManager/system-connections
chmod 755 /mnt/persist/var/lib/nixos
chmod 755 /mnt/persist/var/lib/systemd
chmod 700 /mnt/persist/var/lib/bluetooth
chmod 700 /mnt/persist/var/lib/postgresql
chmod 755 /mnt/persist/var/lib/pipewire
chmod 755 /mnt/persist/var/lib/fwupd
chmod 755 /mnt/persist/var/lib/libvirt
chmod 2755 /mnt/persist/var/log/journal

ok "/persist directory structure ready."

# ── SSH host key — written into /persist ──────────────────────────
# Keys live in /persist/etc/ssh and are bind-mounted to /etc/ssh by
# impermanence on every boot, so the host fingerprint stays stable
# across wipes.
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

  # Copy keys into /persist so they survive root wipes.
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

# ── flake.nix — add impermanence input ────────────────────────────
header "Adding impermanence input to flake.nix…"

# Inject impermanence into the inputs block after the disko input.
# Uses a simple sed approach that works with the existing flake structure.
if ! grep -q "impermanence" "$TMPDIR/flake.nix"; then
  sed -i '/disko = {/,/};/{ /};/a\    impermanence = {\n      url = "github:nix-community/impermanence";\n    };' \
    "$TMPDIR/flake.nix"
  ok "impermanence input added to flake.nix."
else
  ok "impermanence input already present."
fi

# ── Install ────────────────────────────────────────────────────────
header "Installing NixOS…"

cd "$TMPDIR"
git add -A
git \
  -c user.email="bootstrap@localhost" \
  -c user.name="bootstrap" \
  commit -m "bootstrap: generated config for $HOSTNAME with impermanence" \
  --allow-empty --quiet

nixos-install \
  --flake "$TMPDIR#$HOSTNAME" \
  --no-root-passwd \
  --option download-buffer-size 134217728

ok "NixOS installed."

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
