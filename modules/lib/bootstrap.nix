{...}: {
  perSystem = {pkgs, ...}: {
    apps.bootstrap = {
      type = "app";
      program = toString (
        pkgs.writeShellScript "bootstrap" ''
          set -euo pipefail

          # ── Colors ─────────────────────────────────────────────────────────
          BOLD="\033[1m"
          DIM="\033[2m"
          CYAN="\033[1;36m"
          GREEN="\033[1;32m"
          YELLOW="\033[1;33m"
          RED="\033[1;31m"
          RESET="\033[0m"

          header() { echo -e "\n''${CYAN}''${BOLD}$1''${RESET}"; }
          ok()     { echo -e "  ''${GREEN}✓''${RESET}  $1"; }
          info()   { echo -e "  ''${DIM}→''${RESET}  $1"; }
          warn()   { echo -e "  ''${YELLOW}⚠''${RESET}  $1"; }
          err()    { echo -e "  ''${RED}✗''${RESET}  $1"; }
          ask()    { echo -e -n "\n  ''${BOLD}$1''${RESET} "; }

          NIX=(nix --extra-experimental-features "nix-command flakes")

          prompt() {
            local label="$1" default="$2" varname="$3"
            ask "$label [''${DIM}$default''${RESET}]:"
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
            [[ "''${ans,,}" == "y" || "''${ans,,}" == "yes" ]]
          }

          # ── Header ─────────────────────────────────────────────────────────
          clear
          echo -e "''${CYAN}''${BOLD}"
          echo "  ███╗   ██╗██╗██╗  ██╗ ██████╗ ███████╗"
          echo "  ████╗  ██║██║╚██╗██╔╝██╔═══██╗██╔════╝"
          echo "  ██╔██╗ ██║██║ ╚███╔╝ ██║   ██║███████╗"
          echo "  ██║╚██╗██║██║ ██╔██╗ ██║   ██║╚════██║"
          echo "  ██║ ╚████║██║██╔╝ ██╗╚██████╔╝███████║"
          echo "  ╚═╝  ╚═══╝╚═╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝"
          echo -e "''${RESET}"
          echo -e "  ''${DIM}Bootstrap — sets up a new machine from your dotfiles''${RESET}\n"

          # ── Guards ─────────────────────────────────────────────────────────
          if [[ ! -f /etc/NIXOS ]]; then
            err "This script must be run on NixOS."
            exit 1
          fi

          if ! command -v git &>/dev/null; then
            err "git is required. Run first:"
            err "  nix-shell -p git"
            exit 1
          fi

          if ! command -v mkpasswd &>/dev/null; then
            err "mkpasswd is required. Run first:"
            err "  nix-shell -p whois"
            exit 1
          fi

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
            err "Legacy BIOS detected. This config requires UEFI (lanzaboote / systemd-boot)."
            exit 1
          fi

          # ── Auto-detect ────────────────────────────────────────────────────
          header "Auto-detecting system values…"

          DETECTED_USER="nixos"
          DETECTED_SYSTEM="$("''${NIX[@]}" eval --impure --expr 'builtins.currentSystem' --raw 2>/dev/null || echo 'x86_64-linux')"
          DETECTED_TIMEZONE="$(timedatectl show --property=Timezone --value 2>/dev/null || echo 'UTC')"
          DETECTED_LOCALE="$(locale 2>/dev/null | grep '^LANG=' | cut -d= -f2 | tr -d '"' || echo 'en_US.UTF-8')"
          DETECTED_LOCALE="''${DETECTED_LOCALE:-en_US.UTF-8}"
          DETECTED_KB="$(localectl status 2>/dev/null | grep 'X11 Layout' | awk '{print $NF}' || echo 'us')"
          DETECTED_KB="''${DETECTED_KB:-us}"
          DETECTED_HOSTNAME="$(hostname)"
          DETECTED_STATE="$(grep 'system.stateVersion' /etc/nixos/configuration.nix 2>/dev/null | grep -oP '"\K[^"]+' | head -1 || echo '25.11')"
          DETECTED_STATE="''${DETECTED_STATE:-25.11}"
          DETECTED_RAM_KB="$(grep MemTotal /proc/meminfo | awk '{print $2}')"
          DETECTED_RAM_GB="$(( (DETECTED_RAM_KB + 1048575) / 1048576 ))"
          DETECTED_DISK="$(lsblk -d -n -o NAME,TYPE | awk '$2=="disk"{print "/dev/"$1}' | head -1)"
          DETECTED_DISK="''${DETECTED_DISK:-/dev/sda}"

          ok "system       → $DETECTED_SYSTEM"
          ok "timezone     → $DETECTED_TIMEZONE"
          ok "locale       → $DETECTED_LOCALE"
          ok "keyboard     → $DETECTED_KB"
          ok "stateVersion → $DETECTED_STATE"
          ok "RAM          → ''${DETECTED_RAM_GB}GB"

          echo ""
          info "Available disks:"
          lsblk -d -o NAME,SIZE,MODEL | grep -v loop | sed 's/^/    /'

          # ── Interactive prompts ────────────────────────────────────────────
          header "A few things I need from you…"

          prompt "Username to configure"           "$DETECTED_USER"          DETECTED_USER
          DETECTED_HOME="/home/$DETECTED_USER"
          prompt "Hostname for this machine"       "$DETECTED_HOSTNAME"      HOSTNAME
          prompt "Your full name"                  "Your Name"               FULLNAME
          prompt "Your email"                      "you@example.com"         EMAIL
          prompt "Weather city (e.g. New+York)"    "New+York"                WEATHERCITY
          prompt "Dotfiles location on new system" "$DETECTED_HOME/dotfiles" DOTFILESDIR
          prompt "Disk to install to"              "$DETECTED_DISK"          DISK
          prompt "Swap size in GB (>= RAM for hibernate)" "$DETECTED_RAM_GB" SWAP_GB

          # ── Temporary login password ───────────────────────────────────────
          #
          # agenix cannot decrypt user-password.age on a new machine because it
          # is encrypted to the existing desktop host key. We therefore set a
          # plain initial password here that lets the user log in on first boot.
          # Full agenix wiring is restored in a documented post-boot step.
          #
          echo ""
          echo -e "  ''${YELLOW}''${BOLD}Temporary login password''${RESET}"
          echo -e "  ''${DIM}agenix secrets are encrypted to your existing host key and cannot"
          echo -e "  be decrypted on a fresh machine. A temporary password is set so you"
          echo -e "  can log in. Change it or switch to agenix post-boot.''${RESET}\n"

          while true; do
            ask "Temporary password for $DETECTED_USER:"
            read -rs TMP_PASSWORD
            echo ""
            ask "Confirm password:"
            read -rs TMP_PASSWORD2
            echo ""
            if [[ "$TMP_PASSWORD" == "$TMP_PASSWORD2" ]]; then
              break
            fi
            echo -e "  ''${RED}Passwords do not match, try again.''${RESET}"
          done

          TMP_HASHED_PASSWORD="$(mkpasswd -m sha-512 "$TMP_PASSWORD")"
          unset TMP_PASSWORD TMP_PASSWORD2

          # ── Wipe warning ───────────────────────────────────────────────────
          echo ""
          echo -e "  ''${RED}''${BOLD}╔════════════════════════════════════════════════╗''${RESET}"
          echo -e "  ''${RED}''${BOLD}║  WARNING: $DISK WILL BE COMPLETELY WIPED       ║''${RESET}"
          echo -e "  ''${RED}''${BOLD}║  ALL DATA ON THIS DISK WILL BE LOST FOREVER    ║''${RESET}"
          echo -e "  ''${RED}''${BOLD}╚════════════════════════════════════════════════╝''${RESET}"
          echo ""

          # ── Summary ────────────────────────────────────────────────────────
          header "Summary"
          echo ""
          echo -e "    username      = ''${BOLD}$DETECTED_USER''${RESET}"
          echo -e "    fullName      = ''${BOLD}$FULLNAME''${RESET}"
          echo -e "    email         = ''${BOLD}$EMAIL''${RESET}"
          echo -e "    hostname      = ''${BOLD}$HOSTNAME''${RESET}"
          echo -e "    system        = ''${BOLD}$DETECTED_SYSTEM''${RESET}"
          echo -e "    timezone      = ''${BOLD}$DETECTED_TIMEZONE''${RESET}"
          echo -e "    locale        = ''${BOLD}$DETECTED_LOCALE''${RESET}"
          echo -e "    kbLayout      = ''${BOLD}$DETECTED_KB''${RESET}"
          echo -e "    stateVersion  = ''${BOLD}$DETECTED_STATE''${RESET}"
          echo -e "    weatherCity   = ''${BOLD}$WEATHERCITY''${RESET}"
          echo -e "    dotfilesDir   = ''${BOLD}$DOTFILESDIR''${RESET}"
          echo -e "    disk          = ''${RED}''${BOLD}$DISK  ← WILL BE WIPED''${RESET}"
          echo -e "    swap          = ''${BOLD}''${SWAP_GB}GB''${RESET}"
          echo ""

          if ! confirm "Confirm — this will erase $DISK and install NixOS. Proceed?"; then
            warn "Aborted."
            exit 0
          fi

          # ── Trust current user ─────────────────────────────────────────────
          header "Configuring nix trusted user…"

          if ! grep -q "trusted-users" /etc/nix/nix.conf 2>/dev/null; then
            echo "trusted-users = root $DETECTED_USER" | \
              tee -a /etc/nix/nix.conf > /dev/null
            systemctl restart nix-daemon 2>/dev/null || true
            ok "Added $DETECTED_USER to trusted-users."
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

          # Note: osFlakePath / hmFlakePath are written as absolute paths so
          # that builtins.getFlake (used by nixd in nixvim) receives a real
          # path rather than the unexpanded string "$HOME/dotfiles".
          cat > "$TMPDIR/user.nix" <<USERNIX
          {
            # ── Identity ─────────────────────────────────────────────────────────────────
            username      = "$DETECTED_USER";
            fullName      = "$FULLNAME";
            email         = "$EMAIL";
            homeDirectory = "/home/$DETECTED_USER";

            # ── Machine ──────────────────────────────────────────────────────────────────
            hostname     = "$HOSTNAME";
            system       = "$DETECTED_SYSTEM";

            # ── Versions ─────────────────────────────────────────────────────────────────
            stateVersion = "$DETECTED_STATE";

            # ── Locale / Time ────────────────────────────────────────────────────────────
            timezone     = "$DETECTED_TIMEZONE";
            locale       = "$DETECTED_LOCALE";
            kbLayout     = "$DETECTED_KB";

            # ── Paths ────────────────────────────────────────────────────────────────────
            # Shell variables (\$HOME) are left unexpanded so they resolve at runtime
            # inside shell scripts. osFlakePath / hmFlakePath are absolute so that
            # builtins.getFlake receives a real path (nixd LSP requires this).
            wallpaperDir   = "\$HOME/Pictures/wallpapers";
            screenshotsDir = "\$HOME/Pictures/Screenshots";
            notesFile      = "\$HOME/Documents/notes.txt";
            dotfilesDir    = "$DOTFILESDIR";
            osFlakePath    = "$DOTFILESDIR";
            hmFlakePath    = "$DOTFILESDIR";

            # ── Weather ──────────────────────────────────────────────────────────────────
            weatherCity  = "$WEATHERCITY";

            # ── Hardware ─────────────────────────────────────────────────────────────────
            disk = "$DISK";
          }
          USERNIX

          ok "user.nix written."

          # ── Host directory ─────────────────────────────────────────────────
          header "Setting up host directory…"

          HOST_DIR="$TMPDIR/modules/hosts/$HOSTNAME"

          if [[ "$HOSTNAME" == "desktop" ]]; then
            ok "Using existing desktop host directory."
          elif [[ -d "$HOST_DIR" ]]; then
            ok "Host directory already exists."
          else
            mkdir -p "$HOST_DIR"

            # placeholder hardware.nix — replaced after nixos-generate-config
            printf '{ ... }: {}\n' > "$HOST_DIR/hardware.nix"

            # default.nix — mirrors desktop/default.nix exactly (includes self,
            # lanzaboote, and bootstrap-override while it exists)
          # In the HOSTNIX heredoc, change to:
          cat > "$HOST_DIR/default.nix" <<HOSTNIX
          { self, inputs, ... }:
          let
            userConfig = import ../../../user.nix;
          in
          {
            flake.nixosConfigurations.\''${userConfig.hostname} = inputs.nixpkgs.lib.nixosSystem {
              system = userConfig.system;
              specialArgs = { inherit inputs userConfig self; };
              modules =
                (builtins.attrValues self.nixosModules)
                ++ [
                  ./hardware.nix
                  ./disko.nix
                  inputs.disko.nixosModules.disko
                  inputs.lanzaboote.nixosModules.lanzaboote
                ]
                ++ (
                  let p = ./bootstrap-override.nix; in
                  if builtins.pathExists p then [ p ] else [ ]
                );
            };
          }
          HOSTNIX

          ok "Created modules/hosts/$HOSTNAME/default.nix."
          fi

          sed -i 's|inputs.lanzaboote.nixosModules.lanzaboote|inputs.lanzaboote.nixosModules.lanzaboote\n        ./disko.nix\n        inputs.disko.nixosModules.disko|' "$HOST_DIR/default.nix"

          # ── Inject bootstrap-override into desktop host too ────────────────
          # For the desktop host we patch default.nix in-place to include the
          # override while it exists, then restore it after install.
          if [[ "$HOSTNAME" == "desktop" ]]; then
            DESKTOP_DEFAULT="$TMPDIR/modules/hosts/desktop/default.nix"
            cp "$DESKTOP_DEFAULT" "$DESKTOP_DEFAULT.bak"
            # Insert the conditional override include before the closing ];
            sed -i 's|inputs\.lanzaboote\.nixosModules\.lanzaboote|inputs.lanzaboote.nixosModules.lanzaboote\n      ] ++ (\n        let p = ./bootstrap-override.nix; in\n        if builtins.pathExists p then [ p ] else [ ]\n      ) ++ [|' \
              "$DESKTOP_DEFAULT"
          fi

          # Write bootstrap-override.nix into whichever host dir applies.
          # This overrides the agenix-managed password with the temporary one
          # and removes the three secrets that cannot decrypt on this machine.
          cat > "$HOST_DIR/bootstrap-override.nix" <<OVERRIDE
          # bootstrap-override.nix — AUTO-GENERATED, remove after post-boot agenix setup.
          #
          # This file exists because agenix secrets are encrypted to the original host
          # key and cannot be decrypted on a freshly installed machine.
          # It gives the system a working login without agenix.
          #
          # Post-boot steps to restore full agenix:
          #   1. On your existing desktop, add the new machine host pubkey to secrets/secrets.nix
          #      New host pubkey: $(cat /mnt/etc/ssh/ssh_host_ed25519_key.pub 2>/dev/null || echo "<generated during install>")
          #   2. cd ~/dotfiles && agenix -r -i ~/.ssh/id_ed25519
          #   3. git add -A && git commit -m "add $HOSTNAME host key" && git push
          #   4. On this machine: git pull
          #   5. Delete this file: rm $DOTFILESDIR/modules/hosts/$HOSTNAME/bootstrap-override.nix
          #   6. Rebuild: nr
          { lib, ... }:
          {
            # Disable the agenix-managed password — use temporary bootstrap password instead.
            users.users.$DETECTED_USER.hashedPasswordFile = lib.mkForce null;
            users.users.$DETECTED_USER.initialHashedPassword = lib.mkForce "$TMP_HASHED_PASSWORD";

            # Remove the three agenix secrets that cannot decrypt on this host.
            age.secrets.user-password = lib.mkForce { };
            age.secrets.cachix-token   = lib.mkForce { };
            age.secrets.ssh-private-key = lib.mkForce { };
          }
          OVERRIDE

          ok "bootstrap-override.nix written."

          # ── Disko config ───────────────────────────────────────────────────
          header "Generating disko partition layout…"

          SWAP_SIZE="''${SWAP_GB}G"

          cat > "$HOST_DIR/disko.nix" <<DISKO
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
                  swap = {
                    size = "$SWAP_SIZE";
                    content = {
                      type = "swap";
                      resumeDevice = true;
                    };
                  };
                  root = {
                    size = "100%";
                    content = {
                      type = "filesystem";
                      format = "ext4";
                      mountpoint = "/";
                    };
                  };
                };
              };
            };
          }
          DISKO

          ok "disko.nix written."

          # ── Disko — partition, format, mount ───────────────────────────────
          mount -o remount,size=4G /nix/.rw-store 2>/dev/null || true
          header "Partitioning and formatting $DISK…"

          nix run \
            --extra-experimental-features "nix-command flakes" \
            github:nix-community/disko/latest -- \
            --mode destroy,format,mount \
            "$HOST_DIR/disko.nix"

          ok "Disk partitioned, formatted and mounted at /mnt."

          # ── Generate SSH host key ──────────────────────────────────────────
          # Generated BEFORE nixos-install so the key is baked into the system.
          # The pubkey is printed at the end for the agenix re-encryption step.
          header "Generating SSH host key…"

          mkdir -p /mnt/etc/ssh
          if [[ ! -f /mnt/etc/ssh/ssh_host_ed25519_key ]]; then
            ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
            ok "Host key generated."
          else
            ok "Host key already exists."
          fi
          NEW_HOST_PUBKEY="$(cat /mnt/etc/ssh/ssh_host_ed25519_key.pub)"

          # Now that the key exists, rewrite the comment in bootstrap-override.nix
          sed -i "s|<generated during install>|$NEW_HOST_PUBKEY|g" \
            "$HOST_DIR/bootstrap-override.nix"

          # ── Hardware config ────────────────────────────────────────────────
          header "Generating hardware configuration…"

          nixos-generate-config --root /mnt --no-filesystems
          cp /mnt/etc/nixos/hardware-configuration.nix "$HOST_DIR/hardware.nix"
          ok "Hardware config written to modules/hosts/$HOSTNAME/hardware.nix."

          # ── Lanzaboote / Secure Boot ───────────────────────────────────────
          header "Setting up Secure Boot keys…"

          # sbctl creates keys and enrolls them into EFI firmware.
          # lanzaboote reads these keys at nixos-install time to sign the boot
          # files, so they must exist before nixos-install runs.
          mkdir -p /mnt/etc/secureboot
          if sbctl status 2>/dev/null | grep -q "Setup Mode: Enabled"; then
            info "Firmware is in Setup Mode — enrolling Secure Boot keys."
            sbctl create-keys
            sbctl enroll-keys --microsoft
            ok "Secure Boot keys enrolled."
          elif sbctl status 2>/dev/null | grep -q "Secure Boot: disabled"; then
            info "Secure Boot is disabled but not in Setup Mode."
            info "You may need to enter your firmware and enable Setup Mode first."
            info "Attempting key creation anyway (enroll manually if needed)."
            sbctl create-keys || true
            sbctl enroll-keys --microsoft 2>/dev/null || \
              warn "Could not auto-enroll keys. After install, boot into firmware, enable Setup Mode, and run: sbctl enroll-keys --microsoft"
          else
            info "Secure Boot status unclear — creating keys, skipping enroll."
            sbctl create-keys || true
          fi
          # Copy the created keys to the installed system
          if [[ -d /etc/secureboot ]]; then
            cp -r /etc/secureboot /mnt/etc/secureboot
            ok "Secure Boot keys copied to /mnt/etc/secureboot."
          fi

          # ── Install ────────────────────────────────────────────────────────
          header "Installing NixOS…"

          cd "$TMPDIR"
          git add -A

          nixos-install \
            --flake "$TMPDIR#$HOSTNAME" \
            --no-root-passwd \
            --option download-buffer-size 134217728

          ok "NixOS installed."

          # ── Restore desktop default.nix if we patched it ───────────────────
          if [[ "$HOSTNAME" == "desktop" && -f "$TMPDIR/modules/hosts/desktop/default.nix.bak" ]]; then
            mv "$TMPDIR/modules/hosts/desktop/default.nix.bak" \
               "$TMPDIR/modules/hosts/desktop/default.nix"
          fi

          # ── Copy dotfiles to installed system ──────────────────────────────
          header "Copying dotfiles to new system…"

          INSTALL_DOTFILES="/mnt$DOTFILESDIR"
          mkdir -p "$(dirname "$INSTALL_DOTFILES")"
          cp -r "$TMPDIR/." "$INSTALL_DOTFILES/"

          NIXOS_UID="$(grep "^$DETECTED_USER:" /mnt/etc/passwd | cut -d: -f3 || echo 1000)"
          NIXOS_GID="$(grep "^$DETECTED_USER:" /mnt/etc/passwd | cut -d: -f4 || echo 100)"
          chown -R "$NIXOS_UID:$NIXOS_GID" "/mnt$DETECTED_HOME"
          ok "Dotfiles copied to $INSTALL_DOTFILES."

          # ── Done ───────────────────────────────────────────────────────────
          echo ""
          echo -e "''${GREEN}''${BOLD}  ✓ Installation complete!''${RESET}"
          echo ""
          echo -e "  ''${CYAN}''${BOLD}New host pubkey (add this to secrets/secrets.nix):''${RESET}"
          echo -e "  ''${BOLD}$NEW_HOST_PUBKEY''${RESET}"
          echo ""
          echo -e "  ''${YELLOW}''${BOLD}Post-boot steps to restore full agenix:''${RESET}"
          echo -e "  ''${DIM}On your existing desktop:''${RESET}"
          echo -e "    1. Add the pubkey above to secrets/secrets.nix"
          echo -e "    2. agenix -r -i ~/.ssh/id_ed25519"
          echo -e "    3. git add -A && git commit -m 'add $HOSTNAME host key' && git push"
          echo -e "  ''${DIM}On this machine (after first boot + git pull):''${RESET}"
          echo -e "    4. rm $DOTFILESDIR/modules/hosts/$HOSTNAME/bootstrap-override.nix"
          echo -e "    5. nr"
          echo ""
          echo -e "  ''${YELLOW}''${BOLD}Secure Boot note:''${RESET}"
          echo -e "  ''${DIM}If Secure Boot could not be auto-enrolled, boot into your firmware,"
          echo -e "  enable Setup Mode, then run:''${RESET}"
          echo -e "    sbctl enroll-keys --microsoft"
          echo ""

          if confirm "Reboot now?"; then
            reboot
          else
            warn "Remember to reboot before using the system."
          fi
        ''
      );
    };
  };
}
