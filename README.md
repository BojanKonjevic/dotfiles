# bojan's dotfiles

NixOS + Home Manager configuration for a Hyprland desktop. Built to feel clean, cohesive, and easy to reinstall from scratch.

---

## philosophy

The main idea is that the system should be fully described by the config — no hidden state, no manual steps after a fresh install, no "I remember I had to tweak that one thing." Everything declarative, at least as much as possible.

Impermanence is a big part of this. The root filesystem is wiped on every boot by restoring a blank btrfs snapshot. Only things explicitly listed in the config survive reboots. This isn't primarily a security measure — it's about having a clean, predictable system and knowing exactly what's in it. Security is just a nice side effect.

Secure Boot via lanzaboote is similiar: it was easy to add, there's no downside, so why not.

---

## structure

```
hosts/          per-machine config (hardware, disk layout, host-specific values)
modules/        config files, each responsible for one program or small group
profiles/       compositions of modules, imported selectively per host, and some additional options
lib/            flake tooling, scripts, ISO builder
secrets/        agenix-encrypted secrets
user.nix        identity shared across all hosts (name, email, timezone, etc.)
```

**Modules** are primitives. Each one is responsible for a single program (`hyprland.nix`, `kitty`, `zathura`) or a tight cluster that always goes together (`terminal.nix`). They don't know about each other.

**Profiles** are categories that you choose to import per host — `desktop-env.nix`, `media.nix`, `programming.nix`. They're what you actually compose when defining a machine. This makes it easy to imagine a headless server host that only imports `base.nix` and nothing else.

I prefer explicit imports over auto-discovery, even though auto-discovery reduces boilerplate. It's easier to reason about what's actually loaded when you can just read the import list.

---

## hosts

Each host lives in `hosts/<name>/` and has:

- `config.nix` — a plain Nix attrset with all machine-specific values: hostname, disk devices, paths, state version. This is the single source of truth for anything per-machine. It gets merged with `user.nix` and passed everywhere as `userConfig`.
- `default.nix` — the NixOS system definition, imports profiles and hardware config.
- `home.nix` — the Home Manager configuration for that host.
- `hardware.nix`, `disko.nix` — generated/declared disk layout and hardware config.
- Any extra `.nix` files in the host dir are auto-discovered and imported. This is specifically for host-specific things that bootstrap doesn't write — like audio driver quirks — so they survive reinstalls without being clobbered.

---

## bootstrap

The `lib/scripts/bootstrap.sh` script installs the full system from scratch onto a new machine. It:

- auto-detects hardware, generates `config.nix` and all host files
- partitions and formats disks with disko (btrfs + LUKS, separate home disk if provided)
- creates the `@blank` snapshot for impermanence
- sets up the swapfile, `/persist` directory structure, SSH host key
- handles Secure Boot key enrollment on bare metal, skips it on VMs
- runs `nixos-install` and copies the dotfiles to the new system

On reinstall, bootstrap only overwrites files it owns. Host-specific files that already exist are left alone, which is the point of the auto-discovery pattern in `default.nix`.

There's also a custom ISO (`nix build .#iso`) with the bootstrap script baked in as well as some useful tools like zoxide and nvim, usable as a USB installer. There is also a script for testing the ISO quickly in VMs.

---

## the desktop

The entire desktop UI is built on **Quickshell** (QML) — bar, notification popups, notification panel, media/audio panel, app launcher, clipboard managers, wallpaper picker. Everything.

The reason is cohesion. One language, one renderer, one visual style, rather than waybar + swaync + rofi each doing their own thing. The bar and all its panels share a single `barState` object so every panel can know about and react to every other panel cleanly.

Theming is **Catppuccin Mocha** everywhere — Hyprland, Neovim, kitty, vesktop, qBittorrent, zen-browser, hyprlock, the Quickshell UI... The full palette is defined once in `modules/home/theme.nix` and injected into Quickshell as a generated `Colours.qml` singleton at build time, so nothing is hardcoded in QML. Everything not explicitly themed is either automatic with the Catppuccin nixos module or doesn't have it available.

---

## editor

Neovim, configured entirely through **nixvim**. The goal is to have everything expressed in nixvim's options, with `extraPlugins`/`extraFiles` as a bridge for plugins that don't have native nixvim support yet.

LSP is set up for Nix (nixd, with full flake-aware options completion), Python (pyright + ruff), and Lua.

---

## secrets

Managed with **agenix**. Secrets are encrypted to host SSH keys and decrypted at activation. The `bootstrapMode` flag in `config.nix` disables secret decryption during initial install (since the host key doesn't exist in `secrets.nix` yet). After first boot, you add the new host key, re-encrypt, and flip the flag.

---

## storage layout

Example with a seperate home drive:

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
hm                   # switch Home Manager (nh home switch)
nu                   # full update: OS + HM + push to cachix
gc                   # garbage collect, keep last 10 generations
ngens                # list OS generations
hgens                # list HM generations

ns                   # nix package search with fzf preview
gi <owner/repo>      # copy a GitHub repo's full content to clipboard (for LLMs)
```

---

## post-install guide

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

### Verify impermanence

```bash
journalctl -b -u wipe-root       # confirm wipe ran on boot
findmnt | grep persist            # confirm bind-mounts are active
touch /test-impermanence && reboot  # file should be gone after reboot
```

> `/` is wiped on every boot via btrfs `@blank` snapshot restore.
> `/home`, `/nix`, and `/persist` are never wiped.
> Persistent state is bind-mounted from `/persist` on each boot.
