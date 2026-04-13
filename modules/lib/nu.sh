set -euo pipefail

R='\033[0m'
MAUVE='\033[38;2;203;166;247m'
BLUE='\033[38;2;137;180;250m'
GREEN='\033[38;2;166;227;161m'
RED='\033[38;2;243;139;168m'
TEAL='\033[38;2;148;226;213m'
OVERLAY='\033[38;2;127;132;156m'
SUBTEXT='\033[38;2;166;173;200m'
BOLD='\033[1m'

LOG=$(mktemp /tmp/nu-build.XXXXXX)
trap 'rm -f "$LOG"' EXIT

elapsed() {
  printf "${TEAL}%02d:%02d${R}" $(($1 / 60)) $(($1 % 60))
}

badge_ok() { printf "${GREEN}${BOLD} ✓ ${R}${SUBTEXT}%-22s${R}${GREEN}[ok]${R}  " "$1"; }
badge_err() { printf "${RED}${BOLD} ✗ ${R}${SUBTEXT}%-22s${R}${RED}[failed]${R}  " "$1"; }
step() { printf "\n${BLUE}  › ${R}${SUBTEXT}%s${R}\n" "$1"; }
section() { printf "\n${OVERLAY}  ───────────────────────  %s  ────────────────────────${R}\n" "$1"; }

spinner() {
  local pid=$1 msg=$2
  local frames=('⣾' '⣽' '⣻' '⢿' '⡿' '⣟' '⣯' '⣷')
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    printf "\r  ${MAUVE}%s${R}  ${SUBTEXT}%s${R}   " "${frames[$((i % 8))]}" "$msg"
    sleep 0.1
    ((i++)) || true
  done
  printf "\r\033[2K"
}

bar() {
  local pct=$1 label=$2 color=${3:-$MAUVE}
  local total=28
  local filled=$((pct * total / 100))
  local empty=$((total - filled))
  local fill_str="" empty_str=""
  local i
  for ((i = 0; i < filled; i++)); do fill_str+="█"; done
  for ((i = 0; i < empty; i++)); do empty_str+="░"; done
  printf "\r  ${SUBTEXT}%-14s${R}  ${OVERLAY}[${R}${color}%s${R}${OVERLAY}%s${R}${OVERLAY}]${R}  ${SUBTEXT}%3d%%${R}" \
    "$label" "$fill_str" "$empty_str" "$pct"
}

run_build() {
  local label=$1
  shift
  "$@" >"$LOG" 2>&1 &
  local pid=$!
  local pct=0
  while kill -0 "$pid" 2>/dev/null; do
    [[ $pct -lt 95 ]] && pct=$((pct + RANDOM % 4 + 1))
    bar "$pct" "$label" "$BLUE"
    sleep 1.2
  done
  wait "$pid"
  local rc=$?
  if [[ $rc -eq 0 ]]; then
    bar 100 "$label" "$GREEN"
    printf "\n"
  else
    printf "\r\033[2K"
    cat "$LOG"
  fi
  return $rc
}

# ── Parse args ────────────────────────────────────────────────────────────────
UPDATE=false
SKIP_CACHIX=false
for arg in "$@"; do
  [[ $arg == "-u" || $arg == "--update" ]] && UPDATE=true
  [[ $arg == "--no-cache" ]] && SKIP_CACHIX=true
done

# ── Header ────────────────────────────────────────────────────────────────────
clear
printf "\n"
printf "  ${MAUVE}${BOLD}╭──────────────────────────────────────────────────────╮${R}\n"
printf "  ${MAUVE}${BOLD}│                    ❄   nix-update                    │${R}\n"
printf "  ${MAUVE}${BOLD}╰──────────────────────────────────────────────────────╯${R}\n\n"

# ── System info ───────────────────────────────────────────────────────────────
KERNEL=$(uname -r 2>/dev/null || echo "?")
NIXPKGS_REV=$(nix flake metadata "$FLAKE" --json 2>/dev/null |
  python3 -c "
import sys,json
m=json.load(sys.stdin)
print(m.get('locks',{}).get('nodes',{}).get('nixpkgs',{}).get('locked',{}).get('rev','?')[:8])
" 2>/dev/null || echo "?")
GEN_BEFORE=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system \
  2>/dev/null | awk '/current/{print $1}' || echo "?")
HM_GEN_BEFORE=$(nix-env --list-generations \
  --profile "${HOME}/.local/state/nix/profiles/home-manager" \
  2>/dev/null | awk 'END{print $1}' || echo "?")

printf "  ${OVERLAY}system   ${BLUE}%-14s${R}  ${OVERLAY}user     ${BLUE}%s${R}\n" "$(hostname)" "$(whoami)"
printf "  ${OVERLAY}kernel   ${BLUE}%-14s${R}  ${OVERLAY}nixpkgs  ${TEAL}%s…${R}\n" "$KERNEL" "$NIXPKGS_REV"
printf "  ${OVERLAY}gen      ${BLUE}os:%-5s  hm:%-5s${R}\n\n" "$GEN_BEFORE" "$HM_GEN_BEFORE"

# ── Checks ────────────────────────────────────────────────────────────────────
section "CHECKS"

step "checking nix daemon…"
if systemctl is-active --quiet nix-daemon; then
  badge_ok "nix daemon"
  echo
else
  badge_err "nix daemon"
  echo
  printf "  ${RED}run: sudo systemctl start nix-daemon${R}\n"
  exit 1
fi

step "checking internet…"
if ping -c1 -W2 cache.nixos.org &>/dev/null; then
  badge_ok "cache.nixos.org"
  echo
else
  badge_err "no internet"
  echo
  exit 1
fi

step "evaluating flake…"
T0=$SECONDS
nix flake check "$FLAKE" --no-build >"$LOG" 2>&1 &
EVAL_PID=$!
spinner $EVAL_PID "evaluating…"
wait $EVAL_PID && EVAL_OK=true || EVAL_OK=false
EVAL_TIME=$((SECONDS - T0))

if $EVAL_OK; then
  badge_ok "flake eval clean"
  elapsed $EVAL_TIME
  echo
else
  badge_err "eval errors"
  echo
  cat "$LOG"
  exit 1
fi

# ── Update inputs ─────────────────────────────────────────────────────────────
if $UPDATE; then
  section "UPDATE INPUTS"
  step "updating flake.lock…"
  T0=$SECONDS
  (cd "$FLAKE" && nix flake update >"$LOG" 2>&1) &
  UPD_PID=$!
  spinner $UPD_PID "fetching latest refs…"
  wait $UPD_PID
  badge_ok "inputs updated"
  elapsed $((SECONDS - T0))
  echo
fi

# ── NixOS rebuild ─────────────────────────────────────────────────────────────
section "NIXOS BUILD"
step "building system…"
T0=$SECONDS
run_build "nixos" nh os switch "$FLAKE" && OS_OK=true || OS_OK=false
OS_TIME=$((SECONDS - T0))
if $OS_OK; then
  badge_ok "nixos switch"
  elapsed $OS_TIME
  echo
else
  badge_err "nixos switch"
  echo
  exit 1
fi

# ── Home Manager ──────────────────────────────────────────────────────────────
section "HOME MANAGER BUILD"
step "building home-manager…"
T0=$SECONDS
run_build "home-manager" nh home switch "$FLAKE" && HM_OK=true || HM_OK=false
HM_TIME=$((SECONDS - T0))
if $HM_OK; then
  badge_ok "hm switch"
  elapsed $HM_TIME
  echo
else
  badge_err "hm switch"
  echo
  exit 1
fi

# ── Generation diff ───────────────────────────────────────────────────────────
section "CHANGES"

GEN_AFTER=$(sudo nix-env --list-generations --profile /nix/var/nix/profiles/system \
  2>/dev/null | awk '/current/{print $1}' || echo "?")
HM_GEN_AFTER=$(nix-env --list-generations \
  --profile "${HOME}/.local/state/nix/profiles/home-manager" \
  2>/dev/null | awk 'END{print $1}' || echo "?")

printf "\n  ${SUBTEXT}system gen  ${BLUE}%s${R}${OVERLAY} → ${BLUE}%s${R}\n" "$GEN_BEFORE" "$GEN_AFTER"
printf "  ${SUBTEXT}hm gen      ${BLUE}%s${R}${OVERLAY} → ${BLUE}%s${R}\n\n" "$HM_GEN_BEFORE" "$HM_GEN_AFTER"

if command -v nvd &>/dev/null; then
  PREV_PROF="/nix/var/nix/profiles/system-${GEN_BEFORE}-link"
  if [[ -e $PREV_PROF ]]; then
    step "package diff…"
    nvd diff "$PREV_PROF" /nix/var/nix/profiles/system 2>/dev/null |
      sed "s/^Added/  ${GREEN}Added${R}/;s/^Removed/  ${RED}Removed${R}/" |
      head -30
  fi
else
  printf "  ${OVERLAY}(add nvd to packages for a diff)${R}\n"
fi

# ── Cachix push ───────────────────────────────────────────────────────────────
CACHE_OK=true
CACHE_TIME=0
if ! $SKIP_CACHIX && command -v cachix &>/dev/null; then
  section "CACHIX PUSH"
  step "pushing to ${CACHIX_CACHE}…"
  T0=$SECONDS
  (
    CACHIX_AUTH_TOKEN="$(cat /run/agenix/cachix-token)" cachix push "$CACHIX_CACHE" /run/current-system
    CACHIX_AUTH_TOKEN="$(cat /run/agenix/cachix-token)" cachix push "$CACHIX_CACHE" "$HOME/.local/state/nix/profiles/home-manager"
  ) >"$LOG" 2>&1 &
  CACHE_PID=$!
  spinner $CACHE_PID "pushing store paths…"
  wait $CACHE_PID && CACHE_OK=true || CACHE_OK=false
  CACHE_TIME=$((SECONDS - T0))
  if $CACHE_OK; then
    badge_ok "cachix push"
    elapsed $CACHE_TIME
    echo
  else
    badge_err "cachix push"
    echo
    cat "$LOG"
  fi
fi

# ── Summary ───────────────────────────────────────────────────────────────────
TOTAL=$SECONDS
section "SUMMARY"
printf "\n"

$OS_OK && badge_ok "NixOS switch" || badge_err "NixOS switch"
elapsed $OS_TIME
echo

$HM_OK && badge_ok "Home Manager" || badge_err "Home Manager"
elapsed $HM_TIME
echo

if ! $SKIP_CACHIX && command -v cachix &>/dev/null; then
  $CACHE_OK && badge_ok "cachix push" || badge_err "cachix push"
  elapsed $CACHE_TIME
  echo
fi

ALL_OK=true
! $OS_OK && ALL_OK=false
! $HM_OK && ALL_OK=false

printf "\n  ${TEAL}Total time: "
elapsed $TOTAL
$ALL_OK &&
  printf "  ${OVERLAY}│${R}  ${GREEN}${BOLD}done ✓${R}\n\n" ||
  printf "  ${OVERLAY}│${R}  ${RED}${BOLD}failed ✗${R}\n\n"
