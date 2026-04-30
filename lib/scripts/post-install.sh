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

confirm() {
  ask "$1 (y/n):"
  read -r ans
  [[ ${ans,,} == "y" || ${ans,,} == "yes" ]]
}

# ── Guards ─────────────────────────────────────────────────────────
if [[ ! -f /etc/NIXOS ]]; then
  err "This script must be run on the installed NixOS system, not the ISO."
  exit 1
fi

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

# ── Detect dotfiles dir ────────────────────────────────────────────
DOTFILES_DIR=""
for candidate in "$HOME/dotfiles" "$HOME/dotfiles"; do
  if [[ -f "$candidate/flake.nix" ]]; then
    DOTFILES_DIR="$candidate"
    break
  fi
done

if [[ -z $DOTFILES_DIR ]]; then
  ask "Could not auto-detect dotfiles directory. Enter path:"
  read -r DOTFILES_DIR
fi

HOSTNAME="$(hostname)"
HOST_DIR="$DOTFILES_DIR/hosts/$HOSTNAME"
CONFIG_NIX="$HOST_DIR/config.nix"

if [[ ! -f $CONFIG_NIX ]]; then
  err "Could not find $CONFIG_NIX — are you sure this is the right dotfiles directory?"
  exit 1
fi

USERNAME="$(whoami)"

# ── Header ─────────────────────────────────────────────────────────
clear
echo -e "  ${DIM}Post-install — finalize the new system${RESET}\n"
echo -e "  Host:      ${BOLD}$HOSTNAME${RESET}"
echo -e "  User:      ${BOLD}$USERNAME${RESET}"
echo -e "  Dotfiles:  ${BOLD}$DOTFILES_DIR${RESET}"
echo -e "  VM:        ${BOLD}$IS_VM${RESET}"

# ── Step 1: SSH key permissions ────────────────────────────────────
header "Step 1 — Fixing SSH key permissions…"

if [[ -f "$HOME/.ssh/id_ed25519" ]]; then
  chmod 600 "$HOME/.ssh/id_ed25519"
  ok "id_ed25519 → 600"
else
  warn "~/.ssh/id_ed25519 not found — agenix secret may not be decrypted yet."
  warn "This will be fixed after bootstrapMode is disabled and you rebuild."
fi

if [[ -f "$HOME/.ssh/id_ed25519.pub" ]]; then
  chmod 644 "$HOME/.ssh/id_ed25519.pub"
  ok "id_ed25519.pub → 644"
fi

# ── Step 2: Add host key to secrets.nix ───────────────────────────
header "Step 2 — Add host SSH key to secrets.nix…"

HOST_PUBKEY="$(cat /persist/etc/ssh/ssh_host_ed25519_key.pub)"
echo ""
echo -e "  ${BOLD}New host public key:${RESET}"
echo -e "  ${CYAN}$HOST_PUBKEY${RESET}"
echo ""
info "Add this key to $DOTFILES_DIR/secrets/secrets.nix"
info "Opening secrets.nix in nvim…"
sleep 1
nvim "$DOTFILES_DIR/secrets/secrets.nix"

confirm "Done editing secrets.nix?" || { warn "Skipping agenix re-encryption."; }

# ── Step 3: Re-encrypt secrets with agenix ────────────────────────
header "Step 3 — Re-encrypting secrets with agenix…"

cd "$DOTFILES_DIR"
if agenix -r -i "$HOME/.ssh/id_ed25519" 2>/dev/null; then
  ok "Secrets re-encrypted."
else
  warn "agenix failed — you may need to re-run this after setting up SSH."
  warn "Command: cd $DOTFILES_DIR && agenix -r -i ~/.ssh/id_ed25519"
fi

# ── Step 4: Connect to GitHub ──────────────────────────────────────
header "Step 4 — Connect to GitHub…"

echo ""
echo -e "  ${BOLD}Your SSH public key:${RESET}"
echo -e "  ${CYAN}$(cat "$HOME/.ssh/id_ed25519.pub" 2>/dev/null || echo 'key not found')${RESET}"
echo ""
info "Add this key to your GitHub account:"
info "https://github.com/settings/ssh/new"
echo ""

confirm "Added SSH key to GitHub?" || warn "Skipping GitHub SSH test."

header "Testing GitHub SSH connection…"
if ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
  ok "GitHub SSH connection works."
else
  warn "GitHub SSH test inconclusive — continuing anyway."
  info "You can test manually with: ssh -T git@github.com"
fi

# ── Step 5: Switch git remote to SSH ──────────────────────────────
header "Step 5 — Switching git remote to SSH…"

cd "$DOTFILES_DIR"
CURRENT_REMOTE="$(git remote get-url origin 2>/dev/null || echo '')"
if [[ $CURRENT_REMOTE == git@github.com:* ]]; then
  ok "Remote already uses SSH: $CURRENT_REMOTE"
else
  REPO_PATH="$(echo "$CURRENT_REMOTE" | sed 's|https://github.com/||')"
  git remote set-url origin "git@github.com:${REPO_PATH}"
  ok "Remote switched to: git@github.com:${REPO_PATH}"
fi

# ── Step 6: Disable bootstrapMode ─────────────────────────────────
header "Step 6 — Disabling bootstrapMode…"

if grep -q 'bootstrapMode = true' "$CONFIG_NIX"; then
  sed -i 's/bootstrapMode = true/bootstrapMode = false/' "$CONFIG_NIX"
  ok "bootstrapMode set to false in $CONFIG_NIX"
else
  ok "bootstrapMode already false."
fi

# ── Step 7: VM cleanup ─────────────────────────────────────────────
if [[ $IS_VM == "true" ]]; then
  header "Step 7 — Removing bootstrap-override.nix (VM)…"
  OVERRIDE="$HOST_DIR/bootstrap-override.nix"
  if [[ -f $OVERRIDE ]]; then
    rm "$OVERRIDE"
    ok "bootstrap-override.nix removed."
  else
    ok "bootstrap-override.nix already gone."
  fi
fi

# ── Step 8: Commit and push ────────────────────────────────────────
header "Step 8 — Committing and pushing new host config…"

cd "$DOTFILES_DIR"
git add -A
if git diff --cached --quiet; then
  ok "Nothing to commit."
else
  git commit -m "hosts: add $HOSTNAME"
  ok "Committed."
fi

if git push origin main 2>/dev/null; then
  ok "Pushed to origin."
else
  warn "Push failed — you may need to push manually after SSH is set up."
  info "Command: cd $DOTFILES_DIR && git push origin main"
fi

# ── Step 9: Rebuild ────────────────────────────────────────────────
header "Step 9 — Rebuilding system…"

info "Running: nh os switch"
nh os switch "$DOTFILES_DIR"
ok "Rebuild complete."

# ── Step 10: TPM2 LUKS enrollment (bare metal only) ───────────────
if [[ $IS_VM == "false" ]]; then
  header "Step 10 — TPM2 LUKS enrollment…"

  info "Enrolling cryptroot to TPM2…"
  if sudo systemd-cryptenroll \
    --tpm2-device=auto \
    --tpm2-pcrs=0+7 \
    /dev/disk/by-partlabel/disk-main-root; then
    ok "cryptroot enrolled."
  else
    warn "cryptroot enrollment failed — you can retry manually."
  fi

  CONFIG_HOME_DISK="$(grep 'homeDisk' "$CONFIG_NIX" | grep -oP '"[^"]+"' | head -1 | tr -d '"')"
  if [[ -n $CONFIG_HOME_DISK && $CONFIG_HOME_DISK != "" ]]; then
    info "Enrolling crypthome to TPM2…"
    if sudo systemd-cryptenroll \
      --tpm2-device=auto \
      --tpm2-pcrs=0+7 \
      /dev/disk/by-partlabel/disk-home-home; then
      ok "crypthome enrolled."
    else
      warn "crypthome enrollment failed — you can retry manually."
    fi
  fi

  # ── Step 11: Secure Boot ─────────────────────────────────────────
  header "Step 11 — Secure Boot…"

  SBCTL_STATUS="$(sbctl status 2>/dev/null || true)"
  if echo "$SBCTL_STATUS" | grep -q "Secure Boot:.*enabled"; then
    ok "Secure Boot is already enabled."
  else
    echo ""
    warn "Secure Boot is not yet active."
    info "To enroll keys:"
    info "  1. Enter your firmware (reboot, press DEL/F2)"
    info "  2. Enable Setup Mode"
    info "  3. Save and boot back in"
    info "  4. Run: sbctl enroll-keys --microsoft"
    echo ""
    confirm "Do you want to attempt sbctl enroll-keys now?" &&
      sbctl enroll-keys --microsoft ||
      warn "Skipped — run sbctl enroll-keys --microsoft manually."
  fi
fi

# ── Done ───────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}  ✓ Post-install complete!${RESET}"
echo ""
if [[ $IS_VM == "false" ]]; then
  echo -e "  ${DIM}Remember to re-enroll TPM2 after any UEFI firmware updates.${RESET}"
fi
echo ""
