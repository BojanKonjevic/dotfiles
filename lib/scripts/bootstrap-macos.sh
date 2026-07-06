#!/usr/bin/env bash
set -euo pipefail

GIT_REPO="https://github.com/BojanKonjevic/dotfiles"

# ── Auto-detect ──────────────────────────────────────────────────
USERNAME="${USER:-bojan}"
HOME_DIR="${HOME:-/Users/$USERNAME}"
HOSTNAME="${1:-macbook}"
SYSTEM="aarch64-darwin"
BREW_PREFIX="/opt/homebrew"
DOTFILES_DIR="${HOME_DIR}/dotfiles"

echo "═══════════════════════════════════════════════"
echo "    macOS Bootstrap — $HOSTNAME ($SYSTEM)"
echo "═══════════════════════════════════════════════"

# ── 1. Install Nix ────────────────────────────────────────────────
if ! command -v nix &>/dev/null; then
  echo "→ Installing Nix..."
  curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix |
    sh -s -- install --no-confirm
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# ── 2. Install Homebrew ───────────────────────────────────────────
if ! command -v brew &>/dev/null; then
  echo "→ Installing Homebrew..."
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$("${BREW_PREFIX}/bin/brew" shellenv)"
fi

# ── 3. Clone dotfiles ─────────────────────────────────────────────
if [ ! -d "$DOTFILES_DIR" ]; then
  echo "→ Cloning dotfiles..."
  git clone "$GIT_REPO" "$DOTFILES_DIR"
fi

cd "$DOTFILES_DIR"

# ── 4. Create host config ─────────────────────────────────────────
if [ -f "hosts/$HOSTNAME/config.nix" ]; then
  echo "→ hosts/$HOSTNAME/config.nix already exists, leaving it alone."
else
  mkdir -p "hosts/$HOSTNAME"
  cat >"hosts/$HOSTNAME/config.nix" <<CONFIGNIX
{
  hostname = "$HOSTNAME";
  system = "$SYSTEM";
  homeDirectory  = "$HOME_DIR";
  dotfilesDir    = "$DOTFILES_DIR";
  wallpaperDir   = "$HOME_DIR/Pictures/wallpapers";
  screenshotsDir = "$HOME_DIR/Pictures/Screenshots";
  notesFile      = "$HOME_DIR/Documents/notes.txt";

  stateVersion = "25.11";
  darwinSystemVersion = 4;

  # Disables agenix secrets that aren't available yet
  bootstrapMode = true;
}
CONFIGNIX
  echo "→ Config written to hosts/$HOSTNAME/config.nix."
fi

if [ -f "hosts/$HOSTNAME/default.nix" ]; then
  echo "→ hosts/$HOSTNAME/default.nix already exists, leaving it alone."
else
  echo "→ Copying default.nix from template-macos…"
  cp "hosts/template-macos/default.nix" "hosts/$HOSTNAME/default.nix"
fi

# ── 5. First build (bootstrap mode — no secrets) ──────────────────
echo "→ First build (bootstrapMode = true)..."
nix run github:lnl7/nix-darwin -- switch --flake ".#$HOSTNAME" 2>&1 | tee /tmp/darwin-rebuild.log
