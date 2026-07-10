# Adding third-party apps declaratively (nix-darwin + Homebrew)

Rule: never install or configure a third-party app by hand without folding it
back into Nix. Every app goes through four stages — **add, trust, set up,
check** — in that order, and none of them get skipped.

This doc generalizes the process from setting up Boring Notch. Not every app
needs every stage (e.g. Mac App Store apps skip tap/trust; apps with no
preferences skip the settings module), but the order holds.

---

## 1. Add — get the app installable via Nix

Most third-party casks live in a vendor-owned tap, not `homebrew/cask`. You
need the tap as a flake input, then wire it through `nix-homebrew`.

**`flake.nix`** — add the tap repo as a non-flake input:

```nix
inputs.some-app-brew = {
  url = "github:VendorOrg/homebrew-some-app";
  flake = false;
};
```

**App module** (e.g. `modules/system/macos/some-app.nix`) — register the tap
and the cask:

```nix
{inputs, ...}: {
  nix-homebrew.taps."VendorOrg/some-app" = inputs.some-app-brew;
  homebrew.casks = ["some-app"];
}
```

Import the module from whichever host profile should have the app (e.g.
`profiles/system/macos/desktop.nix`).

Find the correct tap owner/repo and cask name from the app's own README —
don't guess; a wrong cask name fails at `brew bundle` with a fetch error
that looks identical to a trust problem (see next section), and you'll
waste time debugging the wrong layer.

## 2. Trust — get the tap actually usable

`nix-homebrew` supports a `trust` option, but has a real limitation worth
understanding before you hit it:

- **A brand-new tap and its trust config landing in the same activation can
  race.** `brew bundle` may try to fetch from the tap before nix-homebrew
  has finished registering it as trusted, producing `Failed to fetch
<cask-name>` even though everything is configured correctly. If you see
  this, try `darwin-rebuild switch` a second time before assuming your
  config is wrong — if the second run succeeds, it confirms this ordering
  issue rather than a real bug.
- **`brew trust` run under `sudo` (as nix-homebrew does it) strips
  `XDG_CONFIG_HOME`.** Homebrew 6.x reads trust state from
  `$XDG_CONFIG_HOME/homebrew/trust.json`, but sudo's fallback writes to
  `~/.homebrew/trust.json` instead. If taps show as untrusted no matter how
  many times you rebuild, this mismatch is why.

**Fix**, once per machine (add to your homebrew module, not per-app):

```nix
{userConfig, pkgs, lib, config, ...}: let
  trustJson = pkgs.writeText "homebrew-trust.json" (builtins.toJSON {
    trustedtaps = config.nix-homebrew.trust.taps;
    trustedformulae = config.nix-homebrew.trust.formulae;
    trustedcasks = config.nix-homebrew.trust.casks;
  });
in {
  # ...nix-homebrew.trust attrs go here, populated by each app module...

  system.activationScripts.setup-homebrew.text = lib.mkBefore ''
    TRUST_DIR="${userConfig.homeDirectory}/.config/homebrew"
    mkdir -p "$TRUST_DIR"
    rm -f "${userConfig.homeDirectory}/.homebrew/trust.json"
    ln -sf "$TRUST_DIR/trust.json" "${userConfig.homeDirectory}/.homebrew/trust.json"
    cp ${trustJson} "$TRUST_DIR/trust.json"
    chmod 644 "$TRUST_DIR/trust.json"
  '';
}
```

Key details that matter here:

- **Generate `trustJson` from `config.nix-homebrew.trust`, never hardcode
  it.** If you hand-write the trust list in the same file, it will silently
  drift from whatever each app module actually declares in
  `nix-homebrew.trust.taps/casks/formulae` — the exact bug that bit us:
  a new app's tap was registered and used, but the hardcoded trust JSON
  never mentioned it, so `brew bundle` kept failing even though the module
  "looked" complete.
- **Use `lib.mkBefore`, not `lib.mkAfter`, for the trust write.** It needs
  to run before nix-homebrew's own tap/bundle steps in the same activation,
  not after.
- **Symlink the fallback path instead of just deleting it.** A one-time
  `rm -f` doesn't survive nix-homebrew re-creating
  `~/.homebrew/trust.json` on a later activation; a symlink to the XDG path
  means whatever writes through the old path lands in the right file
  either way.
- **Heredoc content and terminator must be at column 0.** Nix's `''` string
  indents everything, and `bash` here-docs (`<<'EOF'`) require the closing
  delimiter to have zero leading whitespace or the shell fails to parse it
  (`SC1039`/`SC1073`). Prefer `pkgs.writeText` + `builtins.toJSON` (as
  above) over a raw heredoc entirely — it sidesteps the indentation trap
  and keeps the trust list as real Nix data instead of hand-typed strings.

## 3. Set up — capture the app's real settings

**Do the setup once, by hand, in the GUI.** Guessing preference keys from
source code is slower and more error-prone than just configuring the app
normally and reading back what it wrote. Reserve source-diving for
resolving ambiguity in a dump you already have (unclear types, enum raw
values, etc.), not for guessing keys from scratch.

```bash
defaults read <bundle.id> > ~/before.plist
# configure the app fully in its GUI
defaults read <bundle.id> > ~/after.plist
diff ~/before.plist ~/after.plist
```

Find the bundle ID from `codesign -dv /Applications/SomeApp.app` if it's
not obvious.

**Write the settings into a module.** For a small number of keys, per-key
`defaults write <bundle.id> <key> -bool/-int/-string ...` in a
`home.activation` block is clearest and easiest to diff over time. For a
larger surface (dozens of keys, arrays, structured values), generate a
full plist with `pkgs.writeText` and import it in one shot:

```nix
{userConfig, pkgs, lib, ...}: let
  bundleId = "vendor.some-app";
  settingsPlist = pkgs.writeText "some-app-settings.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>someBoolSetting</key>
      <true/>
      <key>someStringSetting</key>
      <string>Some Value</string>
    </dict>
    </plist>
  '';
in {
  home.activation.someAppSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    defaults import "${bundleId}" "${settingsPlist}"
    killall cfprefsd >/dev/null 2>&1 || true
    killall SomeApp >/dev/null 2>&1 || true
  '';
}
```

Prefer `home.activation` over `system.activationScripts` for per-user app
preferences — it's the correct layer for `NSUserDefaults`-backed settings,
and avoids needing `sudo -u` to fake per-user execution from a system
script. Reserve `system.activationScripts` for genuinely system-level state
(like the homebrew trust file above, which lives outside any one user's
home in spirit even if the path happens to be under `$HOME`).

Kill the app (and `cfprefsd`) after importing — `defaults import` can
succeed silently while a running app keeps its old in-memory copy of the
settings and never re-reads the file until relaunch.

**Deliberately omit values you can't reliably reproduce.** Binary blobs
(e.g. an `NSColor`-encoded accent color), and any value gated behind a
boolean that's currently `false` (so the blob is inert), aren't worth
faithfully round-tripping — note in a comment why it's skipped rather than
guessing at the encoding.

## 4. Check — prove it, don't assume it

The only real proof a settings module is correct is watching it rebuild
from nothing:

```bash
# 1. BEFORE — capture current state
defaults read <bundle.id> > ~/before.plist

# 2. Delete the domain entirely
defaults delete <bundle.id>
defaults read <bundle.id>   # should now error "does not exist"

# 3. DURING — rebuild, watching for your activation script to actually run
darwin-rebuild switch --flake . 2>&1 | tee ~/rebuild.log
grep "Applying <App> settings" ~/rebuild.log

# 4. AFTER — read again and diff
defaults read <bundle.id> > ~/after.plist
diff ~/before.plist ~/after.plist
```

Expect **no output** on the diff, or only lines you already know are
irreducible (see below). Any other diff line means a key, type, or value
didn't round-trip — fix the module, not the live system.

Also worth a final GUI glance: `defaults read` proves the _file_ is right,
but the app may still be running with the old in-memory state if the kill
step in your activation script didn't target the right process name.

## 5. Genuinely irreducible — call these out, don't chase them

Some values will never round-trip, and shouldn't:

- **Runtime-generated identifiers/timestamps.** Update-checker cohort IDs
  (e.g. Sparkle's `SUUpdateGroupIdentifier`), last-check timestamps
  (`SULastCheckTime`) — these regenerate on their own schedule and aren't
  meaningful to seed.
- **Permission prompts** (Accessibility, Input Monitoring, Screen
  Recording, etc.) — confirm once per fresh install; no scripting possible
  without MDM. Note: some apps use a separately-signed helper process
  (e.g. an embedded XPC service) that needs its _own_ permission grant,
  independent of the main app — if a feature silently doesn't work despite
  looking configured correctly, check whether a helper bundle needs its
  own entry in the relevant Privacy & Security pane before assuming it's a
  config bug.
- **OAuth tokens / account sign-in** (Apple ID, iCloud, extension auth for
  things like Raycast) — always re-authed by hand.
- **App state that's SQLite/encrypted/license-bound**, not a plain pref
  file.
- **Confirmed upstream bugs.** If a setting visibly doesn't do what it
  claims (UI updates, hardware doesn't respond), check the project's issue
  tracker before assuming your config is wrong — a `defaults read`/`diff`
  passing cleanly only proves the _value_ was set correctly, not that the
  app's own code correctly acts on it.

Keep a short explicit list of these per app (a comment block in the module,
or a shared `MANUAL.md`) so it's a known bounded set instead of something
rediscovered on every reinstall.
