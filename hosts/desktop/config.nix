# Machine-specific values for the desktop host.
# All fields here are the single source of truth — nothing else should define
# these per-machine values.
{
  # ── Identity ──────────────────────────────────────────────────────────────
  username = "bojan";
  fullName = "Bojan Konjevic";
  email = "konjevicbojan1@gmail.com";

  # ── Machine ───────────────────────────────────────────────────────────────
  hostname = "desktop";
  system = "x86_64-linux";

  # ── Paths ─────────────────────────────────────────────────────────────────
  homeDirectory = "/home/bojan";
  dotfilesDir = "/home/bojan/dotfiles";
  wallpaperDir = "/home/bojan/Pictures/wallpapers";
  screenshotsDir = "/home/bojan/Pictures/Screenshots";
  notesFile = "/home/bojan/Documents/notes.txt";

  # ── nh flake paths (used by NH_OS_FLAKE / NH_HOME_FLAKE env vars) ─────────
  osFlakePath = "/home/bojan/dotfiles";
  hmFlakePath = "/home/bojan/dotfiles";

  # ── Locale ────────────────────────────────────────────────────────────────
  timezone = "Europe/Belgrade";
  locale = "en_US.UTF-8";
  kbLayout = "us";
  weatherCity = "Novi+Sad";

  # ── Versions ──────────────────────────────────────────────────────────────
  stateVersion = "25.11"; # keep in sync with the value used at install time

  # ── Bootstrap flag ────────────────────────────────────────────────────────
  # Set to true via bootstrap-override.nix during initial system setup.
  # Disables agenix secrets that aren't available yet.
  bootstrapMode = false;
}
