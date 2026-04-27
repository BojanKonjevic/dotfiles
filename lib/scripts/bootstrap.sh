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
  if [[ -z $input ]]; then
    printf -v "$varname" "%s" "$default"
  else
    printf -v "$varname" "%s" "$input"
  fi
}

confirm() {
  ask "$1 (y/n):"
  read -r ans
  [[ ${ans,,} == "y" || ${ans,,} == "yes" ]]
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

DETECTED_SYSTEM="$("${NIX[@]}" eval --impure --expr 'builtins.currentSystem' --raw 2>/dev/null || echo 'x86_64-linux')"
DETECTED_HOSTNAME="$(hostname)"
DETECTED_STATE="$(grep 'system.stateVersion' /etc/nixos/configuration.nix 2>/dev/null | grep -oP '"\K[^"]+' | head -1 || echo '25.11')"
DETECTED_STATE="${DETECTED_STATE:-25.11}"
DETECTED_RAM_KB="$(grep MemTotal /proc/meminfo | awk '{print $2}')"
DETECTED_RAM_GB="$(((DETECTED_RAM_KB + 1048575) / 1048576))"
DETECTED_DISK="$(lsblk -d -n -o NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}' | head -1)"
DETECTED_DISK="${DETECTED_DISK:-/dev/sda}"

ok "system       → $DETECTED_SYSTEM"
ok "stateVersion → $DETECTED_STATE"
ok "RAM          → ${DETECTED_RAM_GB}GB"

if [[ $IS_VM == "true" ]]; then
  warn "VM detected ($VIRT_TYPE) — lanzaboote skipped, using systemd-boot."
else
  ok "Bare metal detected — lanzaboote + Secure Boot will be configured."
  if ! command -v sbctl &>/dev/null; then
    err "sbctl is required on bare metal but not found. Run: nix-shell -p sbctl"
    exit 1
  fi
fi

# ── Read user identity from repo ───────────────────────────────────
header "Reading user identity from dotfiles repo…"

_user_nix=$(curl -sf "https://raw.githubusercontent.com/BojanKonjevic/dotfiles/main/user.nix" 2>/dev/null || true)
USERNAME=$(echo "$_user_nix" | grep -oP 'username\s*=\s*"\K[^"]+' || echo "bojan")
HOME_DIR="/home/$USERNAME"
ok "Username: $USERNAME (from user.nix)"

echo ""
info "Available disks:"
lsblk -d -o NAME,SIZE,MODEL | grep -v loop | sed 's/^/    /'

# ── Interactive prompts ────────────────────────────────────────────
header "A few things I need from you…"

prompt "Hostname for this machine" "$DETECTED_HOSTNAME" HOSTNAME
prompt "Dotfiles location on new system" "$HOME_DIR/dotfiles" DOTFILESDIR
prompt "Disk to install to" "$DETECTED_DISK" DISK
ask "Separate drive for /home? Leave blank to use subvolume on main disk:"
read -r HOME_DISK
HOME_DISK="${HOME_DISK:-}"
prompt "Swap size in GB (>= RAM for hibernate)" "$DETECTED_RAM_GB" SWAP_GB

# ── Login password ─────────────────────────────────────────────────
echo ""
echo -e "  ${YELLOW}${BOLD}Login password${RESET}"
echo -e "  ${DIM}agenix secrets are encrypted to your existing host key and cannot"
echo -e "  be decrypted on a fresh machine. A password is set so you"
echo -e "  can log in.${RESET}\n"

while true; do
  ask "Password for $USERNAME:"
  read -rs PASSWORD
  echo ""
  ask "Confirm password:"
  read -rs PASSWORD2
  echo ""
  if [[ $PASSWORD == "$PASSWORD2" ]]; then
    break
  fi
  echo -e "  ${RED}Passwords do not match, try again.${RESET}"
done

HASHED_PASSWORD="$(mkpasswd -m sha-512 "$PASSWORD")"
unset PASSWORD PASSWORD2

# ── Wipe warning ───────────────────────────────────────────────────
warn_text="WARNING: $DISK WILL BE COMPLETELY WIPED"
warn2_text="ALL DATA ON THIS DISK WILL BE LOST FOREVER"
box_width=52

print_warn_line() {
  local text="$1"
  local pad=$((box_width - ${#text} - 4))
  echo -e "  ${RED}${BOLD}║  ${text}$(printf ' %.0s' $(seq 1 $pad))  ║${RESET}"
}

echo -e "  ${RED}${BOLD}╔$(printf '═%.0s' $(seq 1 $box_width))╗${RESET}"
print_warn_line "$warn_text"
if [[ -n $HOME_DISK ]]; then
  print_warn_line "WARNING: $HOME_DISK WILL BE COMPLETELY WIPED"
fi
print_warn_line "$warn2_text"
echo -e "  ${RED}${BOLD}╚$(printf '═%.0s' $(seq 1 $box_width))╝${RESET}"

# ── Summary ────────────────────────────────────────────────────────
header "Summary"
echo ""
echo -e "    username      = ${BOLD}$USERNAME${RESET}  ${DIM}(from user.nix)${RESET}"
echo -e "    hostname      = ${BOLD}$HOSTNAME${RESET}"
echo -e "    system        = ${BOLD}$DETECTED_SYSTEM${RESET}"
echo -e "    stateVersion  = ${BOLD}$DETECTED_STATE${RESET}"
echo -e "    dotfilesDir   = ${BOLD}$DOTFILESDIR${RESET}"
echo -e "    disk          = ${RED}${BOLD}$DISK  ← WILL BE WIPED${RESET}"
echo -e "    swap          = ${BOLD}${SWAP_GB}GB swapfile on @swap subvolume${RESET}"
if [[ -n $HOME_DISK ]]; then
  echo -e "    homeDisk      = ${RED}${BOLD}$HOME_DISK  ← WILL BE WIPED${RESET}"
fi
echo -e "    impermanence  = ${BOLD}/ wiped on every boot via btrfs (@blank snapshot)${RESET}"
if [[ $IS_VM == "true" ]]; then
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

# ── Write hosts/<hostname>/config.nix ─────────────────────────────
header "Writing hosts/$HOSTNAME/config.nix…"

HOST_DIR="$TMPDIR/hosts/$HOSTNAME"
rm -rf "$HOST_DIR"
mkdir -p "$HOST_DIR"

cat >"$HOST_DIR/config.nix" <<CONFIGNIX
# Machine-specific values for the $HOSTNAME host.
# All fields here are the single source of truth — nothing else should define
# these per-machine values.
{
  # ── Machine ───────────────────────────────────────────────────────────────
  hostname = "$HOSTNAME";
  system   = "$DETECTED_SYSTEM";
  homeDisk = "$HOME_DISK";

  # ── Paths ─────────────────────────────────────────────────────────────────
  homeDirectory  = "/home/$USERNAME";
  dotfilesDir    = "$DOTFILESDIR";
  wallpaperDir   = "/home/$USERNAME/Pictures/wallpapers";
  screenshotsDir = "/home/$USERNAME/Pictures/Screenshots";
  notesFile      = "/home/$USERNAME/Documents/notes.txt";

  # ── nh flake paths (used by NH_OS_FLAKE / NH_HOME_FLAKE env vars) ─────────
  osFlakePath = "$DOTFILESDIR";
  hmFlakePath = "$DOTFILESDIR";

  # ── Versions ──────────────────────────────────────────────────────────────
  stateVersion = "$DETECTED_STATE";

  # ── Bootstrap flag ────────────────────────────────────────────────────────
  # Disables agenix secrets that aren't available yet.
  bootstrapMode = true;
}
CONFIGNIX

ok "config.nix written."

# ── hosts/<hostname>/default.nix ──────────────────────────────────
header "Writing hosts/$HOSTNAME/default.nix…"

cat >"$HOST_DIR/default.nix" <<HOSTNIX
{
  self,
  inputs,
  ...
}: let
  userConfig = (import ../../user.nix) // (import ./config.nix);
  bootstrapFiles = [
    "config.nix"
    "default.nix"
    "hardware.nix"
    "disko.nix"
    "home.nix"
    "bootstrap-override.nix"
  ];
  hostDir = ./.;
  extraModules = builtins.filter
    (f: builtins.pathExists f)
    (map
      (f: hostDir + "/\${f}")
      (builtins.filter
        (f: !builtins.elem f bootstrapFiles)
        (builtins.attrNames (builtins.readDir hostDir))));
in {
  flake.nixosConfigurations.\${userConfig.hostname} = inputs.nixpkgs.lib.nixosSystem {
    system = userConfig.system;
    specialArgs = {inherit inputs userConfig self;};
    modules =
      [
        ./hardware.nix
        ./disko.nix
        inputs.disko.nixosModules.disko

        # ── Profiles ───────────────────────────────────────────────────────
        ../../profiles/system/base.nix
        ../../profiles/system/misc.nix
        ../../profiles/system/nvidia.nix
        #../../profiles/system/gaming.nix
      ]
      ++ extraModules;
  };
}
HOSTNIX

ok "default.nix written."

# ── hosts/<hostname>/home.nix ─────────────────────────────────────
header "Writing hosts/$HOSTNAME/home.nix…"

cat >"$HOST_DIR/home.nix" <<HOMENIX
{inputs, ...}: let
  userConfig = (import ../../user.nix) // (import ./config.nix);
  system = userConfig.system;
  pkgs = inputs.nixpkgs.legacyPackages.\${system};
in {
  flake.homeConfigurations.\${userConfig.username} = inputs.home-manager.lib.homeManagerConfiguration {
    inherit pkgs;
    extraSpecialArgs = {
      inherit inputs userConfig;
      quickshell = inputs.quickshell.packages.\${system}.default;
    };
    modules = [
      inputs.catppuccin.homeModules.catppuccin

      # ── Profiles ──────────────────────────────────────────────────────────
      ../../profiles/home/base.nix
      ../../profiles/home/desktop-env.nix
      ../../profiles/home/programming.nix
      ../../profiles/home/media.nix
      ../../profiles/home/misc.nix

      # ── Base HM config ─────────────────────────────────────────────────────
      {
        home.username = userConfig.username;
        home.homeDirectory = userConfig.homeDirectory;
        home.stateVersion = userConfig.stateVersion;
        nix.package = pkgs.nix;
        nix.settings.warn-dirty = false;
        nixpkgs.config.allowUnfree = true;
        news.display = "silent";
      }
    ];
  };
}
HOMENIX

ok "home.nix written."

# ── bootstrap-override.nix (VM only) ──────────────────────────────
if [[ $IS_VM == "true" ]]; then
  header "Writing hosts/$HOSTNAME/bootstrap-override.nix (VM)…"
  printf '%s\n' \
    '{ lib, ... }:' \
    '{' \
    '  boot.loader.systemd-boot.enable = lib.mkOverride 0 true;' \
    '  boot.loader.efi.canTouchEfiVariables = lib.mkOverride 0 true;' \
    '  boot.lanzaboote.enable = lib.mkOverride 0 false;' \
    '}' \
    >"$HOST_DIR/bootstrap-override.nix"
  ok "bootstrap-override.nix written."
fi

# ── hardware.nix placeholder ───────────────────────────────────────
printf '{ ... }: {}\n' >"$HOST_DIR/hardware.nix"

# ── Disko config ───────────────────────────────────────────────────
header "Generating hosts/$HOSTNAME/disko.nix…"

if [[ -n $HOME_DISK ]]; then
  cat >"$HOST_DIR/disko.nix" <<DISKO
{
  disko.devices.disk = {
    main = {
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
              mountOptions = ["fmask=0077" "dmask=0077"];
            };
          };
          root = {
            size = "100%";
            content = {
              type = "luks";
              name = "cryptroot";
              extraFormatArgs = ["--type" "luks2"];
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = ["-L" "root" "-f"];
                subvolumes = {
                  "@" = {
                    mountpoint = "/";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                  "@swap" = {
                    mountpoint = "/swap";
                    mountOptions = ["noatime"];
                  };
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                };
              };
            };
          };
        };
      };
    };
    home = {
      device = "$HOME_DISK";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          home = {
            size = "100%";
            type = "8300";
            content = {
              type = "luks";
              name = "crypthome";
              extraFormatArgs = ["--type" "luks2"];
              settings.allowDiscards = true;
              content = {
                type = "btrfs";
                extraArgs = ["-L" "home" "-f"];
                subvolumes = {
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = ["compress=zstd" "noatime"];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
DISKO
else
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
            mountOptions = ["fmask=0077" "dmask=0077"];
          };
        };
        root = {
          size = "100%";
          content = {
            type = "luks";
            name = "cryptroot";
            extraFormatArgs = ["--type" "luks2"];
            settings.allowDiscards = true;
            content = {
              type = "btrfs";
              extraArgs = ["-L" "root" "-f"];
              subvolumes = {
                "@" = {
                  mountpoint = "/";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@nix" = {
                  mountpoint = "/nix";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@home" = {
                  mountpoint = "/home";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@persist" = {
                  mountpoint = "/persist";
                  mountOptions = ["compress=zstd" "noatime"];
                };
                "@swap" = {
                  mountpoint = "/swap";
                  mountOptions = ["noatime"];
                };
                "@snapshots" = {
                  mountpoint = "/.snapshots";
                  mountOptions = ["compress=zstd" "noatime"];
                };
              };
            };
          };
        };
      };
    };
  };
}
DISKO
fi
ok "disko.nix written (btrfs: @, @nix, @home, @persist, @swap, @snapshots; labeled 'root')."

# ── Register the new host in flake.nix ────────────────────────────
header "Registering $HOSTNAME in flake.nix…"

FLAKE="$TMPDIR/flake.nix"

if grep -q "hosts/${HOSTNAME}/default.nix" "$FLAKE"; then
  ok "flake.nix already contains $HOSTNAME — skipping patch."
else
  awk -v hostname="$HOSTNAME" '
    /hosts\/[^/]+\/default\.nix/ { last_host_line = NR }
    { lines[NR] = $0 }
    END {
      for (i = 1; i <= NR; i++) {
        print lines[i]
        if (i == last_host_line) {
          print "        ./hosts/" hostname "/default.nix"
          print "        ./hosts/" hostname "/home.nix"
        }
      }
    }
  ' "$FLAKE" >"$FLAKE.tmp" && mv "$FLAKE.tmp" "$FLAKE"
  ok "flake.nix patched to include hosts/$HOSTNAME/default.nix and home.nix."
fi

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
mount -o subvolid=5 /dev/mapper/cryptroot "$BTRFS_MNT"

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
mkdir -p /mnt/persist/var/db/sudo
mkdir -p /mnt/persist/var/cache/tuigreet
mkdir -p /mnt/persist/var/log/journal
mkdir -p /mnt/persist/var/lib/systemd

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
chmod 700 /mnt/persist/var/db/sudo
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

# ── Hardware config ────────────────────────────────────────────────
header "Generating hardware configuration…"

nixos-generate-config --root /mnt --no-filesystems
cp /mnt/etc/nixos/hardware-configuration.nix "$HOST_DIR/hardware.nix"
ok "Hardware config written to hosts/$HOSTNAME/hardware.nix."

# ── Secure Boot keys (bare metal only) ────────────────────────────
if [[ $IS_VM == "false" ]]; then
  header "Setting up Secure Boot keys…"

  SBCTL_STATUS="$(sbctl status 2>/dev/null || true)"

  if echo "$SBCTL_STATUS" | grep -q "Setup Mode:"; then
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

  if [[ -d /var/lib/sbctl ]]; then
    cp -r /var/lib/sbctl/. /mnt/persist/etc/secureboot/
    ok "Secure Boot keys copied to /mnt/persist/etc/secureboot."
  else
    err "sbctl ran but /var/lib/sbctl not found — lanzaboote will fail."
    err "Enter your firmware, enable Setup Mode, then re-run bootstrap."
    exit 1
  fi
else
  header "Skipping Secure Boot setup (VM)…"
  info "systemd-boot will be used instead of lanzaboote."
fi

# ── Set initial user password ──────────────────────────────────────
header "Setting initial password for $USERNAME…"

mkdir -p /mnt/persist/passwords
chmod 700 /mnt/persist/passwords
echo "$HASHED_PASSWORD" >/mnt/persist/passwords/"$USERNAME"
chmod 600 /mnt/persist/passwords/"$USERNAME"
unset HASHED_PASSWORD
ok "Password hash written to /persist/passwords/$USERNAME."

# ── Temporary machine-id for bootloader installation ───────────────
header "Creating temporary machine-id for bootloader..."

mkdir -p /mnt/etc
TMP_MACHINE_ID="$(cat /mnt/persist/etc/machine-id)"
echo "$TMP_MACHINE_ID" >/mnt/etc/machine-id
chmod 444 /mnt/etc/machine-id
ok "Temporary machine-id written (reusing persistent ID)."

# ── Install ────────────────────────────────────────────────────────
header "Installing NixOS…"

cd "$TMPDIR"
git add -A
git -c user.email="bootstrap@localhost" \
  -c user.name="bootstrap" \
  commit -m "bootstrap: generated config for $HOSTNAME" \
  --allow-empty --quiet

nixos-install \
  --flake "$TMPDIR#$HOSTNAME" \
  --no-root-passwd \
  --option download-buffer-size 134217728

ok "NixOS installed."

# ── Remove temporary machine-id & adjtime ──────────────────────────
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

if [[ -e /mnt/etc/machine-id ]] || [[ -e /mnt/etc/adjtime ]]; then
  err "Failed to remove temporary files from /mnt/etc"
  exit 1
fi

ok "Temporary files purged."

# ── Copy dotfiles to installed system ──────────────────────────────
header "Clearing old dotfiles from @home..."
rm -rf "/mnt/home/$USERNAME"
ok "Old home directory cleared."
header "Copying dotfiles to new system…"

INSTALL_DOTFILES="/mnt$DOTFILESDIR"
mkdir -p "/mnt$HOME_DIR"
chown 1000:100 "/mnt$HOME_DIR"
chmod 700 "/mnt$HOME_DIR"
mkdir -p "$INSTALL_DOTFILES"
cp -r "$TMPDIR/." "$INSTALL_DOTFILES"
chown -R 1000:100 "/mnt$HOME_DIR"
ok "Dotfiles copied to $INSTALL_DOTFILES."

# ── Done ───────────────────────────────────────────────────────────

if confirm "Reboot now?"; then
  reboot
else
  warn "Remember to reboot before using the system."
fi
