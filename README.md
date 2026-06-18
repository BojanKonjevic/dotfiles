# bojan's dotfiles

NixOS + nix-darwin + Home Manager configuration. Hyprland/Quickshell desktop on Linux, Rift/Raycast on macOS. Built to feel clean, cohesive, and easy to reinstall from scratch.

---

## philosophy

The main idea is that the system should be fully described by the config — no hidden state, no manual steps after a fresh install, no "I remember I had to tweak that one thing." Everything declarative, at least as much as possible.

Impermanence is a big part of this. The root filesystem is wiped on every boot by restoring a blank btrfs snapshot. Only things explicitly listed in the config survive reboots. This isn't primarily a security measure — it's about having a clean, predictable system and knowing exactly what's in it. Security is just a nice side effect.

Secure Boot via lanzaboote is similar: it was easy to add, there's no downside, so why not.

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
user.nix        identity shared across all hosts (name, email, timezone, etc.)
```

**Modules** are primitives. Each one is responsible for a single program (`hyprland.nix`, `kitty`, `zathura`) or a tight cluster that always goes together (`terminal.nix`). They don't know about each other.

**Profiles** are categories that you choose to import per host — `desktop.nix`, `media.nix`, `programming.nix`. They're what you actually compose when defining a machine. This makes it easy to imagine a headless server host that only imports `base.nix` and nothing else.

I prefer explicit imports over auto-discovery, even though auto-discovery reduces boilerplate. It's easier to reason about what's actually loaded when you can just read the import list.

---

## hosts

Each host lives in `hosts/<name>/` and has:

- `config.nix` — a plain Nix attrset with all machine-specific values: hostname, disk devices, paths, state version. This is the single source of truth for anything per-machine. It gets merged with `user.nix` and passed everywhere as `userConfig`.
- `default.nix` — the host definition, imports platform-appropriate system and home profiles.
- NixOS hosts: `hardware.nix`, `disko.nix` — generated/declared disk layout and hardware config.
- macOS hosts: `darwin.nix` — hardware-specific darwin config.

Host definitions for Linux are auto-discovered under `hosts/` via flake-parts. macOS hosts are defined directly in `flake.nix`'s `darwinConfigurations`.

Currently defined hosts:

- **desktop** — NixOS, Hyprland/Quickshell
- **macbook** — macOS, Rift/Raycast

---

## bootstrap

Platform-specific bootstrap scripts live in `lib/scripts/`:

- `bootstrap-nixos.sh` — installs NixOS from scratch: partitions and formats disks with disko, sets up btrfs + LUKS + impermanence, handles Secure Boot, runs `nixos-install`.
- `bootstrap-macos.sh` — installs nix-darwin and Home Manager on a fresh macOS machine.

There's also a custom ISO (`nix build .#iso`) with the bootstrap-nixos script baked in, usable as a USB installer.

---

## the desktop (Linux)

The entire desktop UI is built on **Quickshell** (QML) — bar, notification popups, notification panel, media/audio panel, app launcher, clipboard managers, wallpaper picker. Everything.

The reason is cohesion. One language, one renderer, one visual style, rather than waybar + swaync + rofi each doing their own thing. The bar and all its panels share a single `barState` object so every panel can know about and react to every other panel cleanly.

**Hyprland** is the compositor, with **Hyprlock** for the lockscreen and **Hypridle** for idle management.

Theming is **Catppuccin Mocha** everywhere — Hyprland, Neovim, kitty, vesktop, qBittorrent, zen-browser, hyprlock, the Quickshell UI... The full palette is defined once in `modules/home/shared/theme.nix` and injected into Quickshell as a generated `Colours.qml` singleton at build time, so nothing is hardcoded in QML. Everything not explicitly themed is either automatic with the Catppuccin nixos module or doesn't have it available.

## the desktop (macOS)

**Rift** is the tiling window manager — BSP layout, instant virtual workspaces (10 by default), gesture support, animations. Same keybindings as Hyprland (mod = ⌥, h/j/k/l for focus, Shift to move, numbers for workspaces). **JankyBorders** adds Catppuccin-themed window borders via CGS private APIs (no SIP required, installed from Homebrew, managed as a launchd agent).

**Raycast** replaces the Quickshell panels (launcher, clipboard, system controls) — its config is seeded on first launch via `home.activation`. A native **mic status bar** agent shows mic state via SF Symbols in the menu bar, click to toggle. A **cursor warp agent** warps the cursor to the center of the focused window via event tap and AX observer, mimicking Hyprland's `cursor_warp_to_center`.

macOS default annoyances removed: Dock permanently hidden (999999s delay), Siri fully disabled, Spotlight icon + keyboard shortcuts killed, Mission Control gestures disabled, desktop icons hidden, Stage Manager and native window tiling off, click-wallpaper-reveal-desktop off, spaces never auto-rearrange. The shelf is empty.

---

## editor

Neovim, configured entirely through **nixvim**. The goal is to have everything expressed in nixvim's options, with `extraPlugins`/`extraFiles` as a bridge for plugins that don't have native nixvim support yet.

LSP is set up for Nix (nixd, with full flake-aware options completion), Python (pyright + ruff), and Lua.

---

## secrets

Managed with **agenix**. Secrets are encrypted to host SSH keys and decrypted at activation. Works identically on Linux and macOS. The `bootstrapMode` flag in `config.nix` disables secret decryption during initial install (since the host key doesn't exist in `secrets.nix` yet). After first boot, you add the new host key, re-encrypt, and flip the flag.

---

## storage layout

Example with a separate home drive:

```
/dev/sdx  →  main SSD (root disk)
              ├── /boot        (ESP, vfat)
              └── cryptroot    (LUKS2)
                    └── btrfs
                          ├── @          →  /          (wiped on boot)
                          ├── @nix       →  /nix
                          ├── @persist   →  /persist   (survives wipes)
                          ├── @swap      →  /swap
                          └── @snapshots →  /.snapshots

/dev/sdy  →  home HDD
              └── crypthome   (LUKS2)
                    └── btrfs
                          └── @home      →  /home
```

Bootstrap supports both single-disk and dual-disk setups.

TPM2 is enrolled for LUKS so the passphrase isn't needed on every boot (normal boots unlock automatically; the passphrase remains as a fallback).

---

## useful commands

```bash
nr                   # rebuild and switch OS (nh os switch)
nu                   # full update: OS + HM + push to cachix
gc                   # garbage collect, keep last 10 generations
ngens                # list OS generations

ns                   # nix package search with fzf preview
gi <owner/repo>      # copy a GitHub repo's full content to clipboard (for LLMs)
```

---

## post-install guide (NixOS)

> Run these steps after the first successful boot into the installed system from bootstrap.

### 1. Restore agenix secrets

The new host SSH key was printed at the end of bootstrap. Add it to `secrets/secrets.nix`, then:

```bash
agenix -r -i ~/.ssh/id_ed25519
```

### 2. Fix SSH key permissions

```bash
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

### 3. Connect to GitHub

Add the new SSH public key to your GitHub account, then verify:

```bash
ssh -T git@github.com
```

### 4. Switch git remote to SSH

```bash
git remote set-url origin git@github.com:BojanKonjevic/dotfiles.git
```

### 5. Disable bootstrap mode

In `hosts/<hostname>/config.nix`, set:

```nix
bootstrapMode = false;
```

Then rebuild:

```bash
nr
```

### 6. Push new host to git

Commit and push the new host config and updated `secrets/secrets.nix`.

---

### Physical machines only

**Secure Boot**

If keys could not be auto-enrolled during install, enter your firmware, enable Setup Mode, then run:

```bash
sbctl enroll-keys --microsoft
```

**TPM2 LUKS enrollment**

Bind the LUKS key to this machine's TPM (after Secure Boot is active):

```bash
sudo systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-pcrs=0+7 \
  /dev/disk/by-partlabel/disk-main-root
```

Your passphrase remains as a fallback. Re-enroll after UEFI firmware updates or if you move the drive to another machine.

---

### VM only

Remove the bootstrap override and rebuild:

```bash
rm hosts/<hostname>/bootstrap-override.nix
```

Set `bootstrapMode = false` in `hosts/<hostname>/config.nix`, then `nr`.

---

## post-install guide (macOS)

> Run these steps after `bootstrap-macos.sh` completes.

### 1. Restore agenix secrets

Generate an SSH key, add it to GitHub, add the public key to `secrets/secrets.nix`, then re-encrypt:

```bash
agenix -r -i ~/.ssh/id_ed25519
```

### 2. Disable bootstrap mode

In `hosts/macbook/config.nix`, set `bootstrapMode = false`, then rebuild:

```bash
darwin-rebuild switch --flake .#macbook
```

### 3. Grant accessibility permissions

Several background agents need Accessibility permission. On first build, macOS will prompt for each. Grant all:

- **Rift** — window management, keyboard event tap
- **borders** — observes window events for border updates
- **cursor-warp** — event tap + AX observer for cursor warping on focus changes
- **mic-status-bar** — reads mic state from `/tmp/qs-mic-state`

If you miss the prompts, add them manually in System Settings → Privacy & Security → Accessibility.

### 4. Configure Raycast (optional)

Raycast is seeded with a base config on first launch. After installing extensions and configuring hotkeys, dump the updated config to the repo to persist it:

```bash
cp ~/Library/Application\ Support/com.raycast.macOS/config.json \
  modules/home/macos/raycast/config.json
```

### 5. Push to git

Commit and push the new host config and updated `secrets/secrets.nix`.

---

### Verify impermanence (NixOS only)

```bash
journalctl -b -u wipe-root       # confirm wipe ran on boot
findmnt | grep persist            # confirm bind-mounts are active
touch /test-impermanence && reboot  # file should be gone after reboot
```

> `/` is wiped on every boot via btrfs `@blank` snapshot restore.
> `/home`, `/nix`, and `/persist` are never wiped.
> Persistent state is bind-mounted from `/persist` on each boot.
