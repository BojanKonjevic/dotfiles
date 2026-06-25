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

  # ── Version ───────────────────────────────────────────────────────────────
  stateVersion = "25.11";
  darwinSystemVersion = 4;

  # ── Bootstrap flag ────────────────────────────────────────────────────────
  # Disables agenix secrets that aren't available yet.
  bootstrapMode = true;
}
