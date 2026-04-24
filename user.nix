{
  # ── Identity ─────────────────────────────────────────────────────
  username      = "bojan";
  fullName      = "Bojan Konjevic";
  email         = "konjevicbojan1@gmail.com";
  homeDirectory = "/home/bojan";

  # ── Machine ──────────────────────────────────────────────────────
  hostname     = "desktop";
  system       = "x86_64-linux";

  # ── Versions ─────────────────────────────────────────────────────
  stateVersion = "25.11";

  # ── Locale / Time ────────────────────────────────────────────────
  timezone     = "UTC";
  locale       = "en_US.UTF-8";
  kbLayout     = "(unset)";

  # ── Paths ────────────────────────────────────────────────────────
  wallpaperDir   = "$HOME/Pictures/wallpapers";
  screenshotsDir = "$HOME/Pictures/Screenshots";
  notesFile      = "$HOME/Documents/notes.txt";
  dotfilesDir    = "/home/bojan/dotfiles";
  osFlakePath    = "/home/bojan/dotfiles";
  hmFlakePath    = "/home/bojan/dotfiles";

  # ── Weather ──────────────────────────────────────────────────────
  weatherCity  = "Novi+Sad";

  # ── Hardware ─────────────────────────────────────────────────────
  disk = "/dev/sdb";

  # ── Misc ─────────────────────────────────────────────────────────
  bootstrapMode = true;
}
