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
values, etc.), not for guessing keys from scratch. Where the app has real
public docs (README, manual), check those first for documented preference
keys before resorting to a before/after diff — e.g. MiddleClick's README
documents `fingers`, `allowMoreFingers`, `maxDistanceDelta`, etc. directly,
which is more reliable than reverse-engineering them.

```bash
defaults read <bundle.id> > ~/before.plist
# configure the app fully in its GUI
defaults read <bundle.id> > ~/after.plist
diff ~/before.plist ~/after.plist
```

Find the bundle ID from `codesign -dv /Applications/SomeApp.app` if it's
not obvious.

**Only capture settings you actually changed, not everything that looks
non-default.** A before/after diff mixes real, intentional changes with
incidental state (Raycast's theme IDs, text size, etc. all showed up in an
early diff despite never being touched — they were just already at their
GUI-default values). Capturing incidental state pins you to today's
defaults rather than expressing your actual preferences, and silently
breaks if a future app version ships different defaults. Before writing
the module, go back through the diff and ask "did I actually set this on
purpose?" for each key — if not, drop it.

**Write the settings into a module.** For a small number of keys, per-key
`defaults write <bundle.id> <key> -bool/-int/-string ...` in an activation
block is clearest and easiest to diff over time. For a larger surface
(dozens of keys, arrays, structured values), generate a full plist with
`pkgs.writeText` and import it in one shot — this also avoids the cost of
many sequential `defaults write` invocations (see the reload helper below,
which was built specifically because six separate `defaults write` calls
per app, repeated across several app modules, caused multi-second
activation stalls):

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

**Watch for values that need literal embedded quotes.** Some apps store a
preference as a JSON-encoded string internally (a serialized enum via
`Codable`/`RawRepresentable`, commonly). If the app's own `defaults write`
example uses `-string '"someValue"'` (quotes included in the value, not
just around it), the plist form needs the same literal quotes preserved via
`&quot;`:

```xml
<key>someEnumSetting</key>
<string>&quot;someValue&quot;</string>
```

Dropping the embedded quotes during a `defaults write` → plist conversion
produces a value the app can't parse, and it silently falls back to its own
default — this can look like "the setting didn't apply" when actually the
_value itself_ was wrong, not the write mechanism.

Prefer `home.activation` over `system.activationScripts` for per-user app
preferences — it's the correct layer for `NSUserDefaults`-backed settings,
and avoids needing `sudo -u` to fake per-user execution from a system
script. Reserve `system.activationScripts` for genuinely system-level state
(like the homebrew trust file above), or for apps installed via
`homebrew.casks` at the system level rather than through home-manager
(the common case for most third-party GUI apps in this setup — see the
shared reload helper below).

Kill the app (and `cfprefsd`) after importing — `defaults import` can
succeed silently while a running app keeps its old in-memory copy of the
settings and never re-reads the file until relaunch.

**Deliberately omit values you can't reliably reproduce.** Binary blobs
(e.g. an `NSColor`-encoded accent color), and any value gated behind a
boolean that's currently `false` (so the blob is inert), aren't worth
faithfully round-tripping — note in a comment why it's skipped rather than
guessing at the encoding.

### The shared reload helper

Once you have more than one or two apps doing this, hand-writing the
kill/reload logic per app leads to real, distinct bugs — this setup hit
three in one session: a `killall <app>` that silently no-op'd because the
app ignored `SIGTERM` (needed `-9`), a `killall <app>` that was simply
missing so the settings window kept popping on every rebuild, and repeated
`killall cfprefsd` calls stacking across several app modules, which was the
actual root cause of a ~10 second freeze/beachball on every rebuild.

The fix for all three is one shared, hash-gated helper that every
system-level app module calls, instead of hand-rolling the kill/reload
sequence per app:

```nix
# modules/system/macos/reload-app-prefs.nix
{userConfig}: {
  bundleId,
  appName,
  settingsPlist,
  label ? appName,
}: ''
  echo "Applying ${label} settings..." >&2
  CURRENT_HASH=$(sudo -u "${userConfig.username}" /usr/bin/defaults read "${bundleId}" 2>/dev/null | /usr/bin/openssl md5)
  sudo -u "${userConfig.username}" /usr/bin/defaults import "${bundleId}" "${settingsPlist}"
  NEW_HASH=$(sudo -u "${userConfig.username}" /usr/bin/defaults read "${bundleId}" 2>/dev/null | /usr/bin/openssl md5)
  if [ "$CURRENT_HASH" != "$NEW_HASH" ]; then
    sudo -u "${userConfig.username}" /usr/bin/killall cfprefsd >/dev/null 2>&1 || true
    sudo -u "${userConfig.username}" /usr/bin/killall -9 "${appName}" >/dev/null 2>&1 || true
    sleep 0.5
    sudo -u "${userConfig.username}" open -a "${appName}"
  fi
''
```

Each app module calls it instead of writing its own kill/reload block:

```nix
{userConfig, pkgs, lib, ...}: let
  reloadAppPrefs = import ./reload-app-prefs.nix {inherit userConfig;};
  bundleId = "vendor.some-app";
  settingsPlist = pkgs.writeText "some-app-settings.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>someBoolSetting</key>
      <true/>
    </dict>
    </plist>
  '';
in {
  homebrew.casks = ["some-app"];
  system.activationScripts.postActivation.text = lib.mkAfter (
    reloadAppPrefs {
      inherit bundleId settingsPlist;
      appName = "SomeApp";
    }
  );
}
```

Why each part of the helper matters:

- **Hash-gate before killing anything.** Read the domain, import, read
  again, compare. If nothing changed, skip the kill/relaunch entirely. This
  is the single biggest lever against activation-time slowness — a normal
  rebuild where none of your app settings changed should trigger _zero_
  app kills, not one per app "just in case." It also directly prevents
  several apps' kill/relaunch cycles from stacking in the same activation
  window, which independently caused freezes when multiple hash-gated
  apps _did_ have real changes on the same rebuild (fix: the hash-gate
  naturally limits this to only the apps that actually changed, rather
  than all of them firing together every time).
- **Use `killall -9`, not plain `killall`.** Some apps (confirmed:
  Boring Notch, likely via an XPC helper trapping the signal on the main
  process's behalf) ignore or trap `SIGTERM` and simply don't die from a
  plain `killall`. This can silently make the kill line dead weight for
  months without any visible symptom, since `defaults import` may still
  apply live for some settings — don't assume a `killall` worked just
  because nothing looked broken; verify directly:
  ```bash
  ps aux | grep -i someapp | grep -v grep   # note the PID
  killall SomeApp                            # plain, no -9
  sleep 1
  ps aux | grep -i someapp | grep -v grep   # same PID = it didn't die
  ```
- **`open -a`, not a bare relaunch, and only after the kill has actually
  landed.** Some apps use single-instance activation, where `open -a` on
  an already-running process just brings its window forward (sometimes
  popping a settings/onboarding window as a side effect) rather than
  restarting it — this only shows real new state if the old process is
  genuinely dead first.
- **Local `killall cfprefsd` right before the kill, not relying on a
  centralized one at the very end of activation.** `defaults import`
  writes go through `cfprefsd`, which buffers/flushes lazily — a freshly
  relaunched process can start up and read stale prefs if `cfprefsd` isn't
  refreshed _before_ that specific app's relaunch, even if a
  system-wide `cfprefsd` kill happens later in the same activation run.
  A centralized end-of-activation kill (see below) is still worth having
  as a fallback for apps that write prefs but never relaunch a process
  (e.g. Raycast, whose settings are picked up by an already-running
  instance without needing a restart) — but it isn't sufficient on its
  own for any app you're actively killing and relaunching mid-activation.

**A single centralized `cfprefsd` reload**, run last (after every app
module's own local reload), is still useful as a catch-all — put it in
whichever module holds your other cross-cutting system settings, ordered
to run after all app-specific blocks regardless of file import order:

```nix
system.activationScripts.postActivation.text = lib.mkOrder 2000 ''
  echo "Reloading preferences daemon..." >&2
  sudo -u "${userConfig.username}" /usr/bin/killall cfprefsd >/dev/null 2>&1 || true
'';
```

`lib.mkOrder 2000` (rather than the default `lib.mkAfter`, which is sugar
for `mkOrder 1500`) guarantees this runs after every app module using plain
`mkAfter`, independent of which file is imported first/last in your host
profile — don't rely on import ordering across files for this, confirm it
with an actual timed rebuild log instead of trusting the priority numbers
alone:

```bash
darwin-rebuild switch --flake . 2>&1 | tee ~/rebuild-order.log
grep -n "Applying\|Reloading preferences" ~/rebuild-order.log
```

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

If the module uses the shared reload helper and writes to a domain via
`PlistBuddy Merge` rather than `defaults import`, note that `Merge` may
require the target `.plist` file to already exist — `defaults delete`
removes the file entirely, not just its contents, so a `Merge`-based
module can silently no-op against a missing file on a from-scratch test.
`defaults import` (used by the shared helper) doesn't have this problem,
since it creates the domain/file if absent — prefer it over `Merge` unless
you specifically need to preserve unrelated existing keys in the same
domain (e.g. system-level domains like `com.apple.symbolichotkeys`, which
hold many unrelated hotkeys you don't want to wipe).

Also worth checking after a real settings change (not just a from-scratch
delete): confirm the hash-gate actually fires only for the app you
changed, and that a no-op rebuild afterward triggers zero kills — flip one
setting, rebuild, check the log for exactly one `"Applying ... settings"`
block reaching its kill/relaunch branch, then set it back and rebuild
again to confirm the log shows the hash matching and nothing running.

Also worth a final GUI glance: `defaults read` proves the _file_ is right,
but the app may still be running with the old in-memory state if the kill
step in your activation script didn't target the right process name or
didn't actually kill it (see the `SIGTERM`-ignoring case above).

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
  file. Confirm rather than assume — try `sqlite3 <path> ".tables"`; a
  genuinely encrypted-at-rest file errors with "file is not a database"
  rather than listing tables, which distinguishes it from a merely
  unfamiliar but readable schema.
- **Confirmed upstream bugs.** If a setting visibly doesn't do what it
  claims (UI updates, hardware doesn't respond), check the project's issue
  tracker before assuming your config is wrong — a `defaults read`/`diff`
  passing cleanly only proves the _value_ was set correctly, not that the
  app's own code correctly acts on it.
- **Signals silently ignored by the app.** As above — a `killall` that
  looks like it should work but doesn't (no error, `|| true` swallows
  anything) can hide for a long time. If an app "just doesn't need a
  restart," verify that's actually true rather than assuming your kill
  command is having its intended effect.

Keep a short explicit list of these per app (a comment block in the module,
or a shared `MANUAL.md`) so it's a known bounded set instead of something
rediscovered on every reinstall.
