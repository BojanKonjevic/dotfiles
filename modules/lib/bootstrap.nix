{...}: {
  perSystem = {pkgs, ...}: {
    apps.bootstrap = {
      type = "app";
      program = toString (
        pkgs.writeShellScript "bootstrap" ''
          set -euo pipefail

          # ── Colors ────────────────────────────────────────────────────────
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
            eval "$varname=\"''${input:-$default}\""
          }

          confirm() {
            ask "$1 (y/n):"
            read -r ans
            [[ "''${ans,,}" == "y" || "''${ans,,}" == "yes" ]]
          }

          # ── Header ────────────────────────────────────────────────────────
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

          # ── Guards ────────────────────────────────────────────────────────
          if [[ ! -f /etc/NIXOS ]]; then
            err "This script must be run on NixOS."
            exit 1
          fi

          if ! command -v git &>/dev/null || ! command -v home-manager &>/dev/null; then
            err "git and home-manager are required. Run first:"
            err "  nix-shell -p git home-manager"
            exit 1
          fi

          # ── EFI check ─────────────────────────────────────────────────────
          header "Checking system firmware…"

          if [[ -d /sys/firmware/efi ]]; then
            ok "UEFI detected — systemd-boot will work."
          else
            warn "Legacy BIOS detected. This config uses systemd-boot which requires UEFI."
            warn "If you're on a VM, enable UEFI firmware in your hypervisor settings."
            if ! confirm "Continue anyway?"; then
              err "Aborted."
              exit 1
            fi
          fi

          # ── Auto-detect ───────────────────────────────────────────────────
          header "Auto-detecting system values…"

          DEFAULT_USER="nixos"
          DETECTED_SYSTEM="$("''${NIX[@]}" eval --impure --expr 'builtins.currentSystem' --raw 2>/dev/null || echo 'x86_64-linux')"
          DETECTED_TIMEZONE="$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo 'UTC')"
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
          ok "RAM          → ''${DETECTED_RAM_GB}GB (swap will match for hibernate)"

          echo ""
          info "Available disks:"
          lsblk -d -o NAME,SIZE,MODEL | grep -v loop | sed 's/^/    /'

          # ── Interactive prompts ───────────────────────────────────────────
          header "A few things I need from you…"

          prompt "Username to configure"           "$DEFAULT_USER"            DETECTED_USER
          DETECTED_HOME="/home/$DETECTED_USER"
          prompt "Hostname for this machine"       "$DETECTED_HOSTNAME"      HOSTNAME
          prompt "Host directory name"             "desktop"                 HOSTDIR
          prompt "Your full name"                  "Your Name"               FULLNAME
          prompt "Your email"                      "you@example.com"         EMAIL
          prompt "Weather city (e.g. New+York)"    "New+York"                WEATHERCITY
          prompt "Dotfiles location on new system" "$DETECTED_HOME/dotfiles" DOTFILESDIR
          prompt "Disk to install to"              "$DETECTED_DISK"          DISK
          prompt "Swap size in GB (>= RAM for hibernate)" "$DETECTED_RAM_GB" SWAP_GB

          # ── Wipe warning ──────────────────────────────────────────────────
          echo ""
          echo -e "  ''${RED}''${BOLD}╔════════════════════════════════════════════════╗''${RESET}"
          echo -e "  ''${RED}''${BOLD}║  WARNING: ''${DISK} WILL BE COMPLETELY WIPED    ║''${RESET}"
          echo -e "  ''${RED}''${BOLD}║  ALL DATA ON THIS DISK WILL BE LOST FOREVER    ║''${RESET}"
          echo -e "  ''${RED}''${BOLD}╚════════════════════════════════════════════════╝''${RESET}"
          echo ""

          # ── Summary ───────────────────────────────────────────────────────
          header "Summary"
          echo ""
          echo -e "    username      = ''${BOLD}$DETECTED_USER''${RESET}"
          echo -e "    fullName      = ''${BOLD}$FULLNAME''${RESET}"
          echo -e "    email         = ''${BOLD}$EMAIL''${RESET}"
          echo -e "    hostname      = ''${BOLD}$HOSTNAME''${RESET}  ''${DIM}(nixosConfigurations key)''${RESET}"
          echo -e "    hostDir       = ''${BOLD}modules/hosts/$HOSTDIR''${RESET}  ''${DIM}(directory name)''${RESET}"
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

          # ── Trust current user ────────────────────────────────────────────
          header "Configuring nix trusted user…"

          if ! grep -q "trusted-users" /etc/nix/nix.conf 2>/dev/null; then
            echo "trusted-users = root $DETECTED_USER" | \
              tee -a /etc/nix/nix.conf > /dev/null
            systemctl restart nix-daemon 2>/dev/null || true
            ok "Added $DETECTED_USER to trusted-users."
          else
            ok "Already configured."
          fi

          # ── Clone repo ────────────────────────────────────────────────────
          header "Cloning dotfiles…"

          TMPDIR="/tmp/dotfiles-bootstrap"
          rm -rf "$TMPDIR"
          git clone https://github.com/BojanKonjevic/dotfiles "$TMPDIR"
          ok "Cloned to $TMPDIR."

          # ── Write user.nix ────────────────────────────────────────────────
          header "Writing user.nix…"

          cat > "$TMPDIR/user.nix" <<USERNIX
          # user.nix — single source of truth for everything that differs between machines.
          # Generated by bootstrap — you can edit this file freely afterwards.
          {
            # ── Identity ─────────────────────────────────────────────────────────────────
            username      = "$DETECTED_USER";
            fullName      = "$FULLNAME";
            email         = "$EMAIL";
            homeDirectory = "/home/$DETECTED_USER";

            # ── Machine ───────────────────────────────────────────────────────────────────
            hostname     = "$HOSTNAME";
            system       = "$DETECTED_SYSTEM";

            # ── Versions ──────────────────────────────────────────────────────────────────
            stateVersion = "$DETECTED_STATE";

            # ── Locale / Time ─────────────────────────────────────────────────────────────
            timezone     = "$DETECTED_TIMEZONE";
            locale       = "$DETECTED_LOCALE";
            kbLayout     = "$DETECTED_KB";

            # ── Paths ─────────────────────────────────────────────────────────────────────
            wallpaperDir   = "\$HOME/Pictures/wallpapers";
            screenshotsDir = "\$HOME/Pictures/Screenshots";
            notesFile      = "\$HOME/Documents/notes.txt";
            dotfilesDir    = "$DOTFILESDIR";
            osFlakePath    = "$DOTFILESDIR";
            hmFlakePath    = "$DOTFILESDIR";

            # ── Weather ───────────────────────────────────────────────────────────────────
            weatherCity  = "$WEATHERCITY";

            # ── Hardware ──────────────────────────────────────────────────────────────────
            # Only used by bootstrap for fresh installs via disko.
            disk = "$DISK";
          }
          USERNIX

          ok "user.nix written."

          # ── Host directory ────────────────────────────────────────────────
          header "Setting up host directory…"

          HOST_DIR="$TMPDIR/modules/hosts/$HOSTDIR"
          DESKTOP_DIR="$TMPDIR/modules/hosts/desktop"

          if [[ "$HOSTDIR" == "desktop" ]]; then
            ok "Using existing desktop host directory."
          elif [[ -d "$HOST_DIR" ]]; then
            ok "Host directory already exists, skipping."
          else
            mkdir -p "$HOST_DIR"
            cp "$DESKTOP_DIR/default.nix" "$HOST_DIR/default.nix"
            ok "Created modules/hosts/$HOSTDIR/ from desktop template."
            warn "Remember to review $HOST_DIR/default.nix after install."
          fi

          # ── Generate disko config ─────────────────────────────────────────
          header "Generating disko partition layout…"

          SWAP_SIZE="''${SWAP_GB}G"

          printf '{ ... }: {\n' > "$HOST_DIR/disko.nix"
          printf '  flake.nixosModules.disko-layout = { ... }: {\n' >> "$HOST_DIR/disko.nix"
          printf '    disko.devices.disk.main = {\n' >> "$HOST_DIR/disko.nix"
          printf '      device = "%s";\n' "$DISK" >> "$HOST_DIR/disko.nix"
          printf '      type = "disk";\n' >> "$HOST_DIR/disko.nix"
          printf '      content = {\n' >> "$HOST_DIR/disko.nix"
          printf '        type = "gpt";\n' >> "$HOST_DIR/disko.nix"
          printf '        partitions = {\n' >> "$HOST_DIR/disko.nix"
          printf '          ESP = {\n' >> "$HOST_DIR/disko.nix"
          printf '            size = "512M";\n' >> "$HOST_DIR/disko.nix"
          printf '            type = "EF00";\n' >> "$HOST_DIR/disko.nix"
          printf '            content = {\n' >> "$HOST_DIR/disko.nix"
          printf '              type = "filesystem";\n' >> "$HOST_DIR/disko.nix"
          printf '              format = "vfat";\n' >> "$HOST_DIR/disko.nix"
          printf '              mountpoint = "/boot";\n' >> "$HOST_DIR/disko.nix"
          printf '              mountOptions = [ "fmask=0077" "dmask=0077" ];\n' >> "$HOST_DIR/disko.nix"
          printf '            };\n' >> "$HOST_DIR/disko.nix"
          printf '          };\n' >> "$HOST_DIR/disko.nix"
          printf '          swap = {\n' >> "$HOST_DIR/disko.nix"
          printf '            size = "%s";\n' "$SWAP_SIZE" >> "$HOST_DIR/disko.nix"
          printf '            content = {\n' >> "$HOST_DIR/disko.nix"
          printf '              type = "swap";\n' >> "$HOST_DIR/disko.nix"
          printf '              resumeDevice = true;\n' >> "$HOST_DIR/disko.nix"
          printf '            };\n' >> "$HOST_DIR/disko.nix"
          printf '          };\n' >> "$HOST_DIR/disko.nix"
          printf '          root = {\n' >> "$HOST_DIR/disko.nix"
          printf '            size = "100%%";\n' >> "$HOST_DIR/disko.nix"
          printf '            content = {\n' >> "$HOST_DIR/disko.nix"
          printf '              type = "filesystem";\n' >> "$HOST_DIR/disko.nix"
          printf '              format = "ext4";\n' >> "$HOST_DIR/disko.nix"
          printf '              mountpoint = "/";\n' >> "$HOST_DIR/disko.nix"
          printf '            };\n' >> "$HOST_DIR/disko.nix"
          printf '          };\n' >> "$HOST_DIR/disko.nix"
          printf '        };\n' >> "$HOST_DIR/disko.nix"
          printf '      };\n' >> "$HOST_DIR/disko.nix"
          printf '    };\n' >> "$HOST_DIR/disko.nix"
          printf '  };\n' >> "$HOST_DIR/disko.nix"
          printf '}\n' >> "$HOST_DIR/disko.nix"
          ok "Disko config written to modules/hosts/$HOSTDIR/disko.nix."

          # ── Inject disko into host default.nix ────────────────────────────
          if ! grep -q "disko.nixosModules.disko" "$HOST_DIR/default.nix"; then
          sed -i 's|(builtins.attrValues self.nixosModules)|(builtins.attrValues self.nixosModules) ++ [ inputs.disko.nixosModules.disko ]|' \
          "$HOST_DIR/default.nix"
            ok "Injected disko nixosModule into $HOSTDIR/default.nix."
          fi

          # ── Disko — partition, format, mount ──────────────────────────────
          mount -o remount,size=4G /nix/.rw-store 2>/dev/null || true
          header "Partitioning and formatting $DISK…"

          nix run \
            --extra-experimental-features "nix-command flakes" \
            github:nix-community/disko/latest -- \
            --mode destroy,format,mount \
            --flake "$TMPDIR#$HOSTNAME"

          ok "Disk partitioned, formatted and mounted at /mnt."

          # ── Hardware config ───────────────────────────────────────────────
          header "Generating hardware configuration…"

          nixos-generate-config --root /mnt --no-filesystems
          ok "Hardware config generated."

          info "Wrapping for dendritic pattern…"
          {
            echo "{ ... }: {"
            echo "  flake.nixosModules.hardware ="
            cat /mnt/etc/nixos/hardware-configuration.nix
            echo ";"
            echo "}"
          } > "$HOST_DIR/hardware.nix"
          ok "Hardware config written to modules/hosts/$HOSTDIR/hardware.nix."

          # ── Install ───────────────────────────────────────────────────────
          header "Installing NixOS…"

          cd "$TMPDIR"
          git add -A
          nixos-install \
            --flake "$TMPDIR#$HOSTNAME" \
            --no-root-passwd \
            --option download-buffer-size 134217728 \
            --option store /mnt
          ok "NixOS installed."

          # ── Copy dotfiles to installed system ─────────────────────────────
          header "Copying dotfiles to new system…"

          INSTALL_DOTFILES="/mnt$DOTFILESDIR"
          mkdir -p "$(dirname "$INSTALL_DOTFILES")"
          cp -r "$TMPDIR/." "$INSTALL_DOTFILES/"

          NIXOS_UID="$(grep "^$DETECTED_USER:" /mnt/etc/passwd | cut -d: -f3 || echo 1000)"
          NIXOS_GID="$(grep "^$DETECTED_USER:" /mnt/etc/passwd | cut -d: -f4 || echo 100)"
          chown -R "$NIXOS_UID:$NIXOS_GID" "/mnt$DETECTED_HOME"
          ok "Dotfiles copied to $DOTFILESDIR."

          # ── Done ──────────────────────────────────────────────────────────
          echo ""
          echo -e "''${GREEN}''${BOLD}  ✓ Installation complete!''${RESET}"
          echo ""
          echo -e "  ''${DIM}Home Manager will run automatically on first login.''${RESET}"
          if [[ "$HOSTDIR" != "desktop" ]]; then
            echo ""
            echo -e "  ''${YELLOW}''${BOLD}Reminder:''${RESET} Review modules/hosts/$HOSTDIR/default.nix"
            echo -e "  ''${DIM}and remove any desktop-specific settings (e.g. Nvidia).''${RESET}"
          fi
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
