{...}: {
  perSystem = {pkgs, ...}: {
    apps.bootstrap = {
      type = "app";
      program = builtins.toString (
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

          # ── EFI check ─────────────────────────────────────────────────────
          header "Checking system firmware…"

          if [[ -d /sys/firmware/efi ]]; then
            ok "UEFI detected — systemd-boot will work."
          else
            warn "Legacy BIOS detected. This config uses systemd-boot which requires UEFI."
            warn "If you're on a VM, enable UEFI firmware in your hypervisor settings."
            warn "If you're on real hardware, this config may not boot correctly."
            if ! confirm "Continue anyway?"; then
              err "Aborted."
              exit 1
            fi
          fi

          # ── Auto-detect ───────────────────────────────────────────────────
          header "Auto-detecting system values…"

          ACTUAL_USER="$(whoami)"
          DETECTED_SYSTEM="$(nix eval --impure --expr 'builtins.currentSystem' --raw 2>/dev/null || echo 'x86_64-linux')"
          DETECTED_TIMEZONE="$(timedatectl show --property=Timezone --value 2>/dev/null || cat /etc/timezone 2>/dev/null || echo 'UTC')"
          DETECTED_LOCALE="$(locale 2>/dev/null | grep '^LANG=' | cut -d= -f2 | tr -d '"' || echo 'en_US.UTF-8')"
          DETECTED_LOCALE="''${DETECTED_LOCALE:-en_US.UTF-8}"
          DETECTED_KB="$(localectl status 2>/dev/null | grep 'X11 Layout' | awk '{print $NF}' || echo 'us')"
          DETECTED_KB="''${DETECTED_KB:-us}"
          DETECTED_HOSTNAME="$(hostname)"
          DETECTED_STATE="$(grep 'system.stateVersion' /etc/nixos/configuration.nix 2>/dev/null | grep -oP '"\K[^"]+' | head -1 || echo '25.11')"
          DETECTED_STATE="''${DETECTED_STATE:-25.11}"

          ok "system       → $DETECTED_SYSTEM"
          ok "timezone     → $DETECTED_TIMEZONE"
          ok "locale       → $DETECTED_LOCALE"
          ok "keyboard     → $DETECTED_KB"
          ok "stateVersion → $DETECTED_STATE"

          # ── Interactive prompts ───────────────────────────────────────────
          header "A few things I need from you…"

          prompt "Username to configure"           "$ACTUAL_USER"            DETECTED_USER
          DETECTED_HOME="/home/$DETECTED_USER"
          prompt "Hostname for this machine"       "$DETECTED_HOSTNAME"      HOSTNAME
          prompt "Host directory name"             "desktop"                 HOSTDIR
          prompt "Your full name"                  "Your Name"               FULLNAME
          prompt "Your email"                      "you@example.com"         EMAIL
          prompt "Weather city (e.g. New+York)"    "New+York"                WEATHERCITY
          prompt "Where to clone dotfiles"         "$DETECTED_HOME/dotfiles" DOTFILESDIR

          # ── Confirm ───────────────────────────────────────────────────────
          header "Summary"
          echo ""
          echo -e "    username      = ''${BOLD}$DETECTED_USER''${RESET}"
          echo -e "    fullName      = ''${BOLD}$FULLNAME''${RESET}"
          echo -e "    email         = ''${BOLD}$EMAIL''${RESET}"
          echo -e "    hostname      = ''${BOLD}$HOSTNAME''${RESET}"
          echo -e "    hostDir       = ''${BOLD}modules/hosts/$HOSTDIR''${RESET}"
          echo -e "    system        = ''${BOLD}$DETECTED_SYSTEM''${RESET}"
          echo -e "    timezone      = ''${BOLD}$DETECTED_TIMEZONE''${RESET}"
          echo -e "    locale        = ''${BOLD}$DETECTED_LOCALE''${RESET}"
          echo -e "    kbLayout      = ''${BOLD}$DETECTED_KB''${RESET}"
          echo -e "    stateVersion  = ''${BOLD}$DETECTED_STATE''${RESET}"
          echo -e "    weatherCity   = ''${BOLD}$WEATHERCITY''${RESET}"
          echo -e "    dotfilesDir   = ''${BOLD}$DOTFILESDIR''${RESET}"
          echo ""

          if ! confirm "Looks good?"; then
            warn "Aborted. Re-run the script to try again."
            exit 0
          fi

          # ── Dependencies ──────────────────────────────────────────────────
          header "Ensuring dependencies are available…"

          if ! command -v git &>/dev/null; then
            info "git not found — making temporarily available…"
            export PATH="$(nix build nixpkgs#git --no-link --print-out-paths 2>/dev/null)/bin:$PATH"
            ok "git available."
          else
            ok "git available."
          fi

          # ── Clone repo ────────────────────────────────────────────────────
          header "Setting up dotfiles repo…"

          if [[ -d "$DOTFILESDIR/.git" ]]; then
            ok "Repo already exists at $DOTFILESDIR, skipping clone."
          else
            info "Cloning into $DOTFILESDIR…"
            git clone https://github.com/BojanKonjevic/dotfiles "$DOTFILESDIR"
            ok "Cloned."
          fi

          # ── Write user.nix ────────────────────────────────────────────────
          header "Writing user.nix…"

          cat > "$DOTFILESDIR/user.nix" <<USERNIX
          # user.nix — single source of truth for everything that differs between machines.
          # Generated by bootstrap — you can edit this file freely afterwards.
          rec {
            # ── Identity ───────────────────────────────────────────────────
            username      = "$DETECTED_USER";
            fullName      = "$FULLNAME";
            email         = "$EMAIL";
            homeDirectory = "/home/\''${username}";

            # ── Machine ────────────────────────────────────────────────────
            hostname      = "$HOSTNAME";
            system        = "$DETECTED_SYSTEM";

            # ── Versions ───────────────────────────────────────────────────
            stateVersion  = "$DETECTED_STATE";

            # ── Locale / Time ──────────────────────────────────────────────
            timezone      = "$DETECTED_TIMEZONE";
            locale        = "$DETECTED_LOCALE";
            kbLayout      = "$DETECTED_KB";

            # ── Paths ──────────────────────────────────────────────────────
            wallpaperDir   = "\$HOME/Pictures/wallpapers";
            screenshotsDir = "\$HOME/Pictures/Screenshots";
            notesFile      = "\$HOME/Documents/notes.txt";
            dotfilesDir    = "$DOTFILESDIR";
            osFlakePath    = dotfilesDir;
            hmFlakePath    = dotfilesDir;

            # ── Weather ────────────────────────────────────────────────────
            weatherCity    = "$WEATHERCITY";
          }
          USERNIX

          ok "user.nix written."

          # ── Host directory ────────────────────────────────────────────────
          header "Setting up host directory…"

          HOST_DIR="$DOTFILESDIR/modules/hosts/$HOSTDIR"
          DESKTOP_DIR="$DOTFILESDIR/modules/hosts/desktop"

          if [[ "$HOSTDIR" == "desktop" ]]; then
            ok "Using existing desktop host directory."
          elif [[ -d "$HOST_DIR" ]]; then
            ok "Host directory $HOST_DIR already exists, skipping."
          else
            info "Creating new host directory from desktop template…"
            mkdir -p "$HOST_DIR"
            cp "$DESKTOP_DIR/default.nix" "$HOST_DIR/default.nix"
            ok "Copied modules/hosts/desktop/default.nix → modules/hosts/$HOSTDIR/default.nix"
            warn "Review $HOST_DIR/default.nix — it's a copy of the desktop config."
            warn "Remove or adjust anything specific to the desktop (e.g. Nvidia settings)."
          fi

          # ── Hardware config ───────────────────────────────────────────────
          header "Generating hardware configuration…"

          nixos-generate-config
          ok "Hardware config generated."

          info "Wrapping for dendritic pattern…"
          {
            echo "{ ... }: {"
            echo "  flake.nixosModules.hardware ="
            cat /etc/nixos/hardware-configuration.nix
            echo ";"
            echo "}"
          } > "$HOST_DIR/hardware.nix"

          ok "Hardware config written to modules/hosts/$HOSTDIR/hardware.nix."

          # ── Enable flakes if needed ───────────────────────────────────────
          header "Ensuring flakes are enabled…"

          if ! nix flake --help &>/dev/null; then
            warn "Flakes not enabled — patching /etc/nixos/configuration.nix temporarily…"
            echo 'nix.settings.experimental-features = ["nix-command" "flakes"];' | \
              tee -a /etc/nixos/configuration.nix > /dev/null
            nixos-rebuild switch
            ok "Flakes enabled."
          else
            ok "Flakes already available."
          fi

          # ── Switch ────────────────────────────────────────────────────────
          header "Switching NixOS configuration…"
          cd "$DOTFILESDIR"
          git add -A
          nixos-rebuild switch --flake ".#$HOSTNAME"
          ok "NixOS switched."

          header "Switching Home Manager configuration…"
          home-manager switch --flake ".#$DETECTED_USER"
          ok "Home Manager switched."

          # ── Done ──────────────────────────────────────────────────────────
          echo ""
          echo -e "''${GREEN}''${BOLD}  ✓ Bootstrap complete!''${RESET}"
          echo -e "  ''${DIM}Open a new terminal and you're good to go.''${RESET}"
          if [[ "$HOSTDIR" != "desktop" ]]; then
            echo ""
            echo -e "  ''${YELLOW}''${BOLD}Reminder:''${RESET} Review modules/hosts/$HOSTDIR/default.nix"
            echo -e "  ''${DIM}and remove any desktop-specific hardware settings.''${RESET}"
          fi
          echo ""
        ''
      );
    };
  };
}
