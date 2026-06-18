#!/usr/bin/env bash
set -euo pipefail

GIT_REPO="https://github.com/BojanKonjevic/dotfiles"
DOTFILES_DIR="$HOME/dotfiles"

echo "═══════════════════════════════════════════════"
echo "         macOS Bootstrap — nix-darwin"
echo "═══════════════════════════════════════════════"

# ── 1. Install Nix ──────────────────────────────────────────────────────────
if ! command -v nix &>/dev/null; then
  echo "Installing Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
    sh -s -- install --no-confirm
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# ── 2. Install Homebrew ─────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# ── 3. Clone dotfiles ───────────────────────────────────────────────────────
if [ ! -d "$DOTFILES_DIR" ]; then
  echo "Cloning dotfiles..."
  git clone "$GIT_REPO" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

# ── 4. Create host config ───────────────────────────────────────────────────
HOSTNAME="${1:-macbook}"
if [ ! -f "hosts/$HOSTNAME/config.nix" ]; then
  echo "Creating host config for $HOSTNAME..."
  mkdir -p "hosts/$HOSTNAME"
  cat >"hosts/$HOSTNAME/config.nix" <<EOF
{
  hostname = "$HOSTNAME";
  system = "aarch64-darwin";
  brewPrefix = "/opt/homebrew";
  homeDirectory = "/Users/bojan";
  dotfilesDir = "$DOTFILES_DIR";
  wallpaperDir = "/Users/bojan/Pictures/wallpapers";
  screenshotsDir = "/Users/bojan/Pictures/Screenshots";
  notesFile = "/Users/bojan/Documents/notes.txt";
  osFlakePath = "$DOTFILES_DIR";
  stateVersion = "25.11";
  bootstrapMode = true;
}
EOF
fi

# ── 5. First build (bootstrap mode — no secrets) ─────────────────────────────
echo "First build (bootstrapMode = true)..."
nix run github:lnl7/nix-darwin -- switch --flake ".#$HOSTNAME" 2>&1 | tee /tmp/darwin-rebuild.log

# ── 6. Post-bootstrap instructions ──────────────────────────────────────────
echo ""
echo "═══════════════════════════════════════════════"
echo "  Bootstrap complete!"
echo ""
echo "  NEXT STEPS:"
echo "  1. Generate SSH key:"
echo "     ssh-keygen -t ed25519 -C 'konjevicbojan1@gmail.com'"
echo ""
echo "  2. Add to GitHub:"
echo "     pbcopy < ~/.ssh/id_ed25519.pub"
echo "     → https://github.com/settings/keys"
echo ""
echo "  3. Add key to secrets.nix and re-key:"
echo "     nix run github:ryantm/agenix -- --rekey"
echo ""
echo "  4. Set bootstrapMode = false in hosts/$HOSTNAME/config.nix"
echo ""
echo "  5. Rebuild:"
echo "     darwin-rebuild switch --flake .#$HOSTNAME"
echo ""
echo "  6. Open Raycast (Alt+Space) and go through setup"
echo "═══════════════════════════════════════════════"
