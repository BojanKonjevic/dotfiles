# macOS fresh install — step-by-step

## 1. Run the bootstrap script

```bash
bootstrap-macos.sh
```

## 2. Copy SSH key from existing machine

Use the **same** key everywhere. Do NOT generate a new one.

```bash
# from existing machine
copy from ~/.ssh/id_ed25519
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# load into agent
ssh-add ~/.ssh/id_ed25519
```

## 3. Verify the key matches secrets

The public key must match what's in `secrets/secrets.nix`. If it doesn't:

1. Add the new public key to `secrets/secrets.nix`
2. Remove any old keys that no longer apply
3. Re-encrypt: `agenix -r -i ~/.ssh/id_ed25519`

## 4. Re-encrypt agenix secrets

```bash
agenix -r -i ~/.ssh/id_ed25519
```

## 5. Switch git remote to SSH

```bash
git remote set-url origin git@github.com:BojanKonjevic/dotfiles.git
```

## 6. Test SSH to GitHub

```bash
ssh -T git@github.com
```

## 7. Disable bootstrap mode

In `hosts/<hostname>/config.nix`:

```nix
bootstrapMode = true  →  bootstrapMode = false
```

## 8. Rebuild

```bash
darwin-rebuild switch --flake .#<hostname>
```

## 9. Authenticate cachix

```bash
cachix authtoken "$(cat /run/agenix/cachix-token)"
```
