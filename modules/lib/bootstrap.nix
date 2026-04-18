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

          # sbctl is only required on bare metal — checked after VM detection
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
          # systemd-detect-virt exits 0 and prints the virt type when in a VM,
          # exits non-zero and prints "none" on bare metal.
          VIRT_TYPE="$(systemd-detect-virt 2>/dev/null || echo 'none')"
          if [[ "$VIRT_TYPE" != "none" ]]; then
            IS_VM=true
          else
            IS_VM=false
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

          prompt "Username to configure"           "$DETECTED_USER"          USERNAME
          HOME_DIR="/home/$USERNAME"
          prompt "Hostname for this machine"       "$DETECTED_HOSTNAME"      HOSTNAME
          prompt "Your full name"                  "Your Name"               FULLNAME
          prompt "Your email"                      "you@example.com"         EMAIL
          prompt "Weather city (e.g. New+York)"    "New+York"                WEATHERCITY
          prompt "Dotfiles location on new system" "$HOME_DIR/dotfiles"      DOTFILESDIR
          prompt "Disk to install to"              "$DETECTED_DISK"          DISK
          prompt "Swap size in GB (>= RAM for hibernate)" "$DETECTED_RAM_GB" SWAP_GB

          # ── Temporary login password ───────────────────────────────────────
          #
          # agenix cannot decrypt user-password.age on a new machine because it
          # is encrypted to the existing host key. A temporary plain password is
          # set so the user can log in on first boot. Full agenix is restored in
          # the documented post-boot steps.
          #
          echo ""
          echo -e "  ''${YELLOW}''${BOLD}Temporary login password''${RESET}"
          echo -e "  ''${DIM}agenix secrets are encrypted to your existing host key and cannot"
          echo -e "  be decrypted on a fresh machine. A temporary password is set so you"
          echo -e "  can log in. Change it or switch to agenix post-boot.''${RESET}\n"

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
          echo -e "    username      = ''${BOLD}$USERNAME''${RESET}"
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
          if [[ "$IS_VM" == "true" ]]; then
            echo -e "    bootloader    = ''${YELLOW}''${BOLD}systemd-boot (VM — lanzaboote skipped)''${RESET}"
          else
            echo -e "    bootloader    = ''${BOLD}lanzaboote + Secure Boot''${RESET}"
          fi
          echo ""

          if ! confirm "Confirm — this will erase $DISK and install NixOS. Proceed?"; then
            warn "Aborted."
            exit 0
          fi

          # ── Trust current user ─────────────────────────────────────────────
          header "Configuring nix trusted user…"

          if ! grep -q "trusted-users" /etc/nix/nix.conf 2>/dev/null; then
            echo "trusted-users = root $USERNAME" | \
              tee -a /etc/nix/nix.conf > /dev/null
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

          # osFlakePath / hmFlakePath are written as absolute paths so that
          # builtins.getFlake (used by nixd in nixvim) receives a real path.
          cat > "$TMPDIR/user.nix" <<USERNIX
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
            # \$HOME is left unexpanded so it resolves at runtime in shell
            # scripts. osFlakePath / hmFlakePath are absolute for nixd LSP.
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
          # Always generate a clean host directory in the tmp clone regardless
          # of whether the hostname already exists in the repo. The repo on disk
          # is never touched — only this tmp clone is used for the install.
          header "Setting up host directory for '$HOSTNAME'…"

          HOST_DIR="$TMPDIR/modules/hosts/$HOSTNAME"
          mkdir -p "$HOST_DIR"

          # Placeholder hardware.nix — replaced after nixos-generate-config.
          printf '{ ... }: {}\n' > "$HOST_DIR/hardware.nix"

          # ── default.nix — VM vs bare metal ────────────────────────────────
          # On a VM: lanzaboote is omitted entirely; systemd-boot is used via
          # bootstrap-override.nix. On bare metal: lanzaboote is included and
          # Secure Boot keys are enrolled before nixos-install runs.
          if [[ "$IS_VM" == "true" ]]; then
            cat > "$HOST_DIR/default.nix" <<HOSTNIX
          { self, inputs, ... }:
          let
            userConfig = import ../../../user.nix;
          in {
            flake.nixosConfigurations.\''${userConfig.hostname} = inputs.nixpkgs.lib.nixosSystem {
              system = userConfig.system;
              specialArgs = { inherit inputs userConfig self; };
              modules =
                (builtins.attrValues self.nixosModules)
                ++ [
                  ./hardware.nix
                  ./disko.nix
                  inputs.disko.nixosModules.disko
                ]
                ++ (
                  let p = ./bootstrap-override.nix; in
                  if builtins.pathExists p then [ p ] else []
                );
            };
          }
          HOSTNIX
          else
            cat > "$HOST_DIR/default.nix" <<HOSTNIX
          { self, inputs, ... }:
          let
            userConfig = import ../../../user.nix;
          in {
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
                  if builtins.pathExists p then [ p ] else []
                );
            };
          }
          HOSTNIX
          fi

          ok "default.nix written."

          # ── bootstrap-override.nix ─────────────────────────────────────────
          # VM: enables systemd-boot, forces lanzaboote off (lanzaboote.nix in
          # nixosModules sets boot.lanzaboote.enable = true unconditionally, so
          # mkForce is needed even though the lanzaboote nixosModules.lanzaboote
          # input module is not imported in the VM default.nix).
          # Bare metal: only sets the temporary password.
          # agenix secrets are already gated by bootstrapMode = true in
          # agenix.nix so no mkForce null on hashedPasswordFile is needed.
          if [[ "$IS_VM" == "true" ]]; then
            cat > "$HOST_DIR/bootstrap-override.nix" <<OVERRIDE
          # bootstrap-override.nix — AUTO-GENERATED, delete after post-boot agenix setup.
          #
          # Generated for a VM install — uses systemd-boot instead of lanzaboote.
          # On bare metal reinstall, run bootstrap again; it will detect real hardware
          # and generate the correct lanzaboote config automatically.
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

            # lanzaboote.nix (a nixosModule in self.nixosModules) sets
            # boot.lanzaboote.enable = true, which in turn does mkForce false on
            # systemd-boot. Override both here so the VM boots correctly.
            boot.loader.systemd-boot.enable = lib.mkForce true;
            boot.loader.efi.canTouchEfiVariables = lib.mkForce true;
            boot.lanzaboote.enable = lib.mkForce false;
          }
          OVERRIDE
          else
            cat > "$HOST_DIR/bootstrap-override.nix" <<OVERRIDE
          # bootstrap-override.nix — AUTO-GENERATED, delete after post-boot agenix setup.
          #
          # agenix secrets are encrypted to the original host key and cannot be
          # decrypted on a freshly installed machine. This file provides a
          # temporary login password until agenix is re-keyed for this host.
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

          # ── Disko config (btrfs) ───────────────────────────────────────────
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
                      type = "btrfs";
                      extraArgs = [ "-L" "nixos" "-f" ];
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

          ok "disko.nix written (btrfs: @, @nix, @home, @snapshots)."

          # ── Disko — partition, format, mount ───────────────────────────────
          mount -o remount,size=4G /nix/.rw-store 2>/dev/null || true
          header "Partitioning and formatting $DISK…"

          nix run \
            --extra-experimental-features "nix-command flakes" \
            github:nix-community/disko/latest -- \
            --mode destroy,format,mount \
            "$HOST_DIR/disko.nix"

          ok "Disk partitioned, formatted and mounted at /mnt."

          # ── SSH host key ───────────────────────────────────────────────────
          # Must be generated before nixos-install so agenix can reference it.
          # The pubkey is printed at the end for the re-encryption step.
          header "Generating SSH host key…"

          mkdir -p /mnt/etc/ssh
          chmod 700 /mnt/etc/ssh
          if [[ ! -f /mnt/etc/ssh/ssh_host_ed25519_key ]]; then
            ssh-keygen -t ed25519 -N "" -f /mnt/etc/ssh/ssh_host_ed25519_key
            chmod 600 /mnt/etc/ssh/ssh_host_ed25519_key
            chmod 644 /mnt/etc/ssh/ssh_host_ed25519_key.pub
            ok "Host key generated."
          else
            ok "Host key already exists, reusing."
          fi
          NEW_HOST_PUBKEY="$(cat /mnt/etc/ssh/ssh_host_ed25519_key.pub)"

          # Inject the real pubkey into the override comment now that we have it.
          sed -i "s|<generated during install>|$NEW_HOST_PUBKEY|g" \
            "$HOST_DIR/bootstrap-override.nix"

          # ── Hardware config ────────────────────────────────────────────────
          header "Generating hardware configuration…"

          nixos-generate-config --root /mnt --no-filesystems
          cp /mnt/etc/nixos/hardware-configuration.nix "$HOST_DIR/hardware.nix"
          ok "Hardware config written."

          # ── Secure Boot keys (bare metal only) ────────────────────────────
          if [[ "$IS_VM" == "false" ]]; then
            # sbctl keys must exist before nixos-install so lanzaboote can sign
            # the boot files during installation. Keys are created on the live
            # ISO and copied to the installed system's secureboot path.
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
              mkdir -p /mnt/etc/secureboot
              cp -r /etc/secureboot/. /mnt/etc/secureboot/
              ok "Secure Boot keys copied to /mnt/etc/secureboot."
            else
              err "sbctl ran but /etc/secureboot not found — lanzaboote will fail."
              err "Enter your firmware, enable Setup Mode, then re-run bootstrap."
              exit 1
            fi
          else
            header "Skipping Secure Boot setup (VM)…"
            info "systemd-boot will be used instead of lanzaboote."
          fi

          # ── Install ────────────────────────────────────────────────────────
          header "Installing NixOS…"

          cd "$TMPDIR"
          git add -A
          # Commit so nixos-install sees a clean tree and emits no dirty warning.
          git \
            -c user.email="bootstrap@localhost" \
            -c user.name="bootstrap" \
            commit -m "bootstrap: generated config for $HOSTNAME" \
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

          # NixOS users are activated on first boot so /mnt/etc/passwd won't
          # have the user yet. UID 1000 / GID 100 is the correct default for a
          # single-user NixOS system and matches what nixos-install will create.
          chown -R 1000:100 "/mnt$HOME_DIR"
          ok "Dotfiles copied to $INSTALL_DOTFILES."

          # ── Done ───────────────────────────────────────────────────────────
          echo ""
          echo -e "''${GREEN}''${BOLD}  ✓ Installation complete!''${RESET}"
          echo ""
          echo -e "  ''${CYAN}''${BOLD}New host pubkey (add this to secrets/secrets.nix):''${RESET}"
          echo -e "  ''${BOLD}$NEW_HOST_PUBKEY''${RESET}"
          echo ""
          echo -e "  ''${YELLOW}''${BOLD}Post-boot steps to restore full agenix:''${RESET}"
          echo -e "  ''${DIM}On your existing machine:''${RESET}"
          echo -e "    1. Add the pubkey above to secrets/secrets.nix"
          echo -e "    2. agenix -r -i ~/.ssh/id_ed25519"
          echo -e "    3. git add -A && git commit -m 'add $HOSTNAME host key' && git push"
          echo -e "  ''${DIM}On this machine (after first boot + git pull):''${RESET}"
          echo -e "    4. rm $DOTFILESDIR/modules/hosts/$HOSTNAME/bootstrap-override.nix"
          echo -e "    5. Set bootstrapMode = false in user.nix"
          echo -e "    6. nr"
          echo ""
          if [[ "$IS_VM" == "false" ]]; then
            echo -e "  ''${YELLOW}''${BOLD}Secure Boot note:''${RESET}"
            echo -e "  ''${DIM}If keys could not be auto-enrolled, enter your firmware,"
            echo -e "  enable Setup Mode, then run:''${RESET}"
            echo -e "    sbctl enroll-keys --microsoft"
            echo ""
          fi

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
