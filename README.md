# My dotfiles

NixOS + nix-darwin + Home Manager configuration. Hyprland/Quickshell on Linux, Rift/Raycast on macOS. Built to feel clean, cohesive, and easy to reinstall from scratch.

---

## philosophy

The system should be described by the config as much as possible — no hidden state, no "I remember I had to tweak that one thing." A handful of things stay manual by necessity (Raycast extension config, TCC permission prompts, OAuth logins) rather than by choice, and those exceptions are called out where they come up instead of pretending they don't exist.

Impermanence is a big part of this on the NixOS side. The root filesystem is wiped on every boot by restoring a blank btrfs snapshot. Only things explicitly listed in the config survive reboots. This isn't primarily a security measure — it's about having a clean, predictable system and knowing exactly what's in it. Security is just a nice side effect. Secure Boot via lanzaboote is similar: it was easy to add, there's no downside, so why not.

Secrets are managed with **agenix**, encrypted to host SSH keys and decrypted at activation, identically on both platforms.

---

## structure

```
hosts/          per-machine config (hardware, disk layout, host-specific values)
modules/        config files, each responsible for one program or small group
  home/shared/    home-manager modules for both platforms
  home/nixos/     home-manager modules for Linux
  home/macos/     home-manager modules for macOS
  system/nixos/   NixOS system modules
  system/macos/   nix-darwin system modules
profiles/       compositions of modules, imported selectively per host
  home/shared/    home-manager profiles for both platforms
  home/nixos/     home-manager profiles for Linux
  home/macos/     home-manager profiles for macOS
  system/shared/  system profiles for both platforms
  system/nixos/   NixOS system profiles
  system/macos/   nix-darwin system profiles
lib/            flake tooling, scripts, ISO builder
secrets/        agenix-encrypted secrets
docs/           deeper write-ups (fresh install, TCC permissions, adding apps)
user.nix        identity shared across all hosts (name, email, timezone, etc.)
```

**Modules** are primitives. Each one is responsible for a single program (`hyprland.nix`, `ghostty`, `zathura`) or a tight cluster that always goes together (`terminal.nix`). They don't know about each other.

**Profiles** are categories you choose to import per host — `desktop.nix`, `media.nix`, `programming.nix`. They're what you actually compose when defining a machine. This makes it easy to imagine a headless server host that only imports `base.nix` and nothing else.

I prefer explicit imports over auto-discovery, even though auto-discovery reduces boilerplate. It's easier to reason about what's actually loaded when you can just read the import list.

---

## hosts

Each host lives in `hosts/<name>/` and has:

- `config.nix` — a plain Nix attrset with all machine-specific values: hostname, disk devices, paths, state version. This is the single source of truth for anything per-machine. It gets merged with `user.nix` and passed everywhere as `userConfig`.
- `default.nix` — the host definition, imports platform-appropriate system and home profiles.
- NixOS hosts: `hardware.nix`, `disko.nix` — generated/declared disk layout and hardware config.

All hosts under `hosts/` (except `template-nixos` and `template-macos`) are auto-discovered by `flake.nix` and flake-parts. Each host's `default.nix` defines its own entry — `nixosConfigurations` for NixOS or `darwinConfigurations` for macOS — using the hostname from its `config.nix`.

Currently defined hosts:

- **desktop** — NixOS, Hyprland/Quickshell
- **macbook** — macOS, Rift/Raycast (daily driver)

---

## the desktop (Linux)

The entire desktop UI is built on **Quickshell** (QML) — bar, notification popups, notification panel, media/audio panel, app launcher, clipboard managers, wallpaper picker. Everything.

The reason is cohesion. One language, one renderer, one visual style, rather than waybar + swaync + rofi each doing their own thing. The bar and all its panels share a single `barState` object so every panel can know about and react to every other panel cleanly.

**Hyprland** is the compositor, with **Hyprlock** for the lockscreen and **Hypridle** for idle management.

Theming is **Catppuccin Mocha** everywhere — Hyprland, Neovim, ghostty, vesktop, qBittorrent, zen-browser, hyprlock, the Quickshell UI... The full palette is defined once in `modules/home/shared/theme.nix` and injected into Quickshell as a generated `Colours.qml` singleton at build time, so nothing is hardcoded in QML. Everything not explicitly themed is either automatic with the Catppuccin nixos module or doesn't have it available.

## the macbook (macOS)

**Rift** is the tiling window manager — BSP layout, instant virtual workspaces (10 by default), gesture support, animations. Same keybindings as Hyprland (mod = ⌥, h/j/k/l for focus, Shift to move, numbers for workspaces). **JankyBorders** adds Catppuccin-themed window borders via CGS private APIs (no SIP required, installed from Homebrew, managed as a launchd agent).

Global key-blocking (Cmd+Q/W/N/M/H reclaimed for Rift's own bindings) runs through **Karabiner-Elements**, configured declaratively via Nix rather than a hand-written daemon — per-app exceptions and blocked keys are just data in `modules/home/macos/karabiner.nix`. Rift's own synthetic key events bypass Karabiner's HID-level grabber, so its bindings keep working even for keys it blocks globally.

**Raycast** replaces the Quickshell panels (launcher, clipboard, system controls) — its config is seeded on first launch via `home.activation`. Extension setup and hotkey configuration beyond that base config are done by hand, then the config is dumped back into the repo to persist. A native **mic status bar** agent shows mic state via SF Symbols in the menu bar, click to toggle.

macOS default annoyances removed: Dock permanently hidden (999999s delay), Siri fully disabled, Spotlight icon + keyboard shortcuts killed, Mission Control gestures disabled, desktop icons hidden, Stage Manager and native window tiling off, click-wallpaper-reveal-desktop off, spaces never auto-rearrange. The shelf is empty.

---

## bootstrap

Platform-specific bootstrap scripts live in `lib/scripts/`:

- `bootstrap-nixos.sh` — installs NixOS from scratch: partitions and formats disks with disko, sets up btrfs + LUKS + impermanence, handles Secure Boot, runs `nixos-install`. Interactive prompts for hostname, disk selection, etc. There's also a custom ISO (`nix build .#iso`) with this script baked in, usable as a USB installer.
- `bootstrap-macos.sh` — installs nix-darwin and Home Manager on a fresh macOS machine. Auto-detects architecture, user, and home directory. Optional first argument sets the hostname (default: `macbook`).

Full post-install walkthroughs (SSH keys, agenix registration, disabling bootstrap mode, TCC permissions, etc.) live in `docs/`, not here.

---

## see also

- `docs/macos-fresh-install.md` — step-by-step post-bootstrap setup for macOS
- `docs/macos-tcc-permissions.md` — batching Accessibility/Input Monitoring/etc. approval prompts
- `docs/macos-new-apps.md` — the add/trust/setup/check workflow for folding a new third-party app into Nix
