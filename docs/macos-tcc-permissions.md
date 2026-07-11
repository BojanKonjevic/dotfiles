# Managing TCC permissions (Accessibility, Input Monitoring, etc.)

macOS's TCC framework requires user consent for Accessibility, Input
Monitoring, Full Disk Access, Screen Recording, and other sensitive APIs.
There's no declarative `defaults write`-equivalent — Apple requires either a
GUI click or an MDM-deployed profile, and profiles/GUI-scripting/direct DB
writes are all dead ends or too fragile/heavy to be worth it here (signing
requirements, SIP, schema churn). So: manual approval it is, just batched.

## Approach: batch-trigger script

Run one script right after a fresh install that launches/exercises every
app and codepath needing a TCC grant, back-to-back — so all the "Allow"
dialogs come at once instead of trickling in over the first week of use.

Still manual (you click through each prompt), just collapses the ad-hoc
"why is this asking now" moments into a single five-minute pass.

### `tcc-warmup.sh`

- Grouped by TCC service, so you're not context-switching mid-service.
- Each entry should actually exercise the codepath that triggers the
  prompt — some apps only ask on first real use of the API, not on launch.
- Gate it behind a manual command (e.g. `just tcc-warmup`), not
  `system.activationScripts` — it's interactive, so it shouldn't fire
  during an unattended `darwin-rebuild switch`.
- Worth adding an idempotency check later (skip apps already granted) if
  re-runs become annoying — TCC.db can be read (not written) with
  `sqlite3` for many services if you have Full Disk Access yourself.

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "== Accessibility =="
# open -a "SomeApp"

echo "== Input Monitoring =="
# open -a "cliclick"

echo "== Full Disk Access =="
# open -a "Terminal"

echo "== Screen Recording =="
# open -a "SomeScreenshotTool"

echo "== Automation =="
# osascript -e 'tell application "Finder" to get name of every disk'

echo "All triggers fired — go click Allow on everything now."
```

Fill in the commented lines with the actual apps/commands that need each
permission, then run it once per fresh install.
