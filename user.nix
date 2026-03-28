# user.nix — single source of truth for everything that differs between machines.
# This is the only file you need to edit when cloning these dotfiles on a new machine.
{
  # ── Identity ─────────────────────────────────────────────────────────────────
  username = "bojan";
  fullName = "Bojan Konjevic";
  email = "konjevicbojan1@gmail.com";
  homeDirectory = "/home/bojan";

  # ── Machine ──────────────────────────────────────────────────────────────────
  hostname = "nixos";
  system = "x86_64-linux";

  # ── Versions ─────────────────────────────────────────────────────────────────
  stateVersion = "25.11"; # shared by both home-manager and NixOS

  # ── Locale / Time ────────────────────────────────────────────────────────────
  timezone = "Europe/Belgrade";
  locale = "en_US.UTF-8";
  kbLayout = "us"; # keyboard layout — must match in both Hyprland and xserver

  # ── Paths ────────────────────────────────────────────────────────────────────
  # Shell variables ($HOME, etc.) are intentionally left unexpanded so they
  # resolve at runtime inside the shell scripts that use these strings.
  wallpaperDir = "$HOME/Pictures/wallpapers";
  screenshotsDir = "$HOME/Pictures/Screenshots";
  notesFile = "$HOME/Documents/notes.txt";
  dotfilesDir = "$HOME/dotfiles"; # root of this repo on the machine
  osFlakePath = "$HOME/dotfiles/"; # where the NixOS system flake lives
  hmFlakePath = "$HOME/dotfiles/"; # where the home-manager flake lives

  # ── Weather ──────────────────────────────────────────────────────────────────
  weatherCity = "Novi+Sad"; # wttr.in city string (use + for spaces)

  # ── Hardware ─────────────────────────────────────────────────────────────────
  # Only used by the bootstrap script for fresh installs via disko.
  # Check available disks with: lsblk -d -o NAME,SIZE,MODEL
  # Common values: /dev/sda, /dev/nvme0n1, /dev/vda (VM)
  disk = "/dev/sda";
}
