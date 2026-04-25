# Post-Install Guide

> Run these steps after the first successful boot into the installed system from bootstrap.

---

## 1. Restore agenix secrets

The new host SSH key was printed at the end of bootstrap. Add it to `secrets/secrets.nix`, then:

```bash
agenix -r -i ~/.ssh/id_ed25519
```

## 2. Fix SSH key permissions

```bash
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub
```

## 3. Connect to GitHub

Add the new SSH public key to your GitHub account, then verify:

```bash
ssh -T git@github.com
```

## 4. Switch git remote to SSH

```bash
git remote set-url origin git@github.com:BojanKonjevic/dotfiles.git
```

## 5. Disable bootstrap mode

In `hosts/<hostname>/config.nix`, set:

```nix
bootstrapMode = false;
```

Then rebuild:

```bash
nr
```

## 6. Push new host to git

Commit and push the new host config and updated `secrets/secrets.nix`.

---

## Physical machines only

### Secure Boot

If keys could not be auto-enrolled during install, enter your firmware, enable Setup Mode, then run:

```bash
sbctl enroll-keys --microsoft
```

### TPM2 LUKS enrollment

Bind the LUKS key to this machine's TPM (after Secure Boot is active):

```bash
sudo systemd-cryptenroll \
  --tpm2-device=auto \
  --tpm2-pcrs=0+7 \
  /dev/disk/by-partlabel/disk-main-root
```

Your passphrase remains as a fallback. Re-enroll after UEFI firmware updates or if you move the drive to another machine.

---

## VM only

Remove the bootstrap override and rebuild:

```bash
rm hosts/<hostname>/bootstrap-override.nix
```

Set `bootstrapMode = false` in `hosts/<hostname>/config.nix`, then `nr`.

---

## Verify impermanence

```bash
journalctl -b -u wipe-root       # confirm wipe ran on boot
findmnt | grep persist            # confirm bind-mounts are active
touch /test-impermanence && reboot  # file should be gone after reboot
```

> `/` is wiped on every boot via btrfs `@blank` snapshot restore.
> `/home`, `/nix`, and `/persist` are never wiped.
> Persistent state is bind-mounted from `/persist` on each boot.
