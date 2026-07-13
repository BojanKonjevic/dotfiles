{
  pkgs,
  lib,
  ...
}: let
  bundleId = "eu.exelban.Stats";

  settingsPlist = pkgs.writeText "stats-settings.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Battery_state</key>
      <integer>1</integer>
      <key>Battery_widget</key>
      <string>battery</string>

      <key>Bluetooth_state</key>
      <integer>0</integer>

      <key>CPU_state</key>
      <integer>1</integer>
      <key>CPU_widget</key>
      <string>line_chart</string>

      <key>Clock_state</key>
      <integer>0</integer>

      <key>Disk_state</key>
      <integer>1</integer>
      <key>Disk_widget</key>
      <string>bar_chart</string>

      <key>GPU_state</key>
      <integer>1</integer>
      <key>GPU_widget</key>
      <string>mini</string>

      <key>Network_state</key>
      <integer>1</integer>
      <key>Network_widget</key>
      <string>speed</string>

      <key>RAM_state</key>
      <integer>1</integer>
      <key>RAM_widget</key>
      <string>bar_chart</string>

      <key>Sensors_state</key>
      <integer>1</integer>
      <key>Sensors_widget</key>
      <string>label</string>

      <key>update-interval</key>
      <string>Never</string>

      <key>runAtLoginInitialized</key>
      <integer>1</integer>
      <key>setupProcess</key>
      <integer>1</integer>
    </dict>
    </plist>
  '';

  appName = "Stats";
in {
  home.activation.statsSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Applying ${appName} settings..." >&2
    CURRENT_HASH=$(/usr/bin/defaults read "${bundleId}" 2>/dev/null | /usr/bin/openssl md5)
    /usr/bin/defaults import "${bundleId}" "${settingsPlist}"
    NEW_HASH=$(/usr/bin/defaults read "${bundleId}" 2>/dev/null | /usr/bin/openssl md5)
    if [ "$CURRENT_HASH" != "$NEW_HASH" ]; then
      /usr/bin/killall cfprefsd >/dev/null 2>&1 || true
      /usr/bin/killall -9 "${appName}" >/dev/null 2>&1 || true
      sleep 0.5
      open -a "${appName}"
    fi
  '';
}
