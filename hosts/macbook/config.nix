# Machine-specific values for the macbook host.
# All fields here are the single source of truth — nothing else should define
# these per-machine values.
{
  # ── Machine ───────────────────────────────────────────────────────────────
  hostname = "macbook";
  system = "aarch64-darwin";

  # ── Paths ─────────────────────────────────────────────────────────────────
  homeDirectory = "/Users/bojan";
  dotfilesDir = "/Users/bojan/dotfiles";
  wallpaperDir = "/Users/bojan/Pictures/wallpapers";
  screenshotsDir = "/Users/bojan/Pictures/Screenshots";
  notesFile = "/Users/bojan/Documents/notes.txt";

  # ── nh flake paths (used by NH_OS_FLAKE / NH_HOME_FLAKE env vars) ─────────
  osFlakePath = "/Users/bojan/dotfiles";

  # ── Version ───────────────────────────────────────────────────────────────
  stateVersion = "25.11";

  # ── macOS brew prefix ──────────────────────────────────────────────────
  brewPrefix = "/opt/homebrew";

  # ── Bootstrap flag ────────────────────────────────────────────────────────
  # Disables agenix secrets that aren't available yet.
  bootstrapMode = true;
}
