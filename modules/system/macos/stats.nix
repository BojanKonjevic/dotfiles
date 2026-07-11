{
  inputs,
  userConfig,
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

      <!-- Irreducible: updater_check_ts (timestamp), version (changes on update) -->
    </dict>
    </plist>
  '';
in {
  homebrew.casks = ["stats"];

  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "Applying Stats settings..." >&2
    sudo -u "${userConfig.username}" defaults import "${bundleId}" "${settingsPlist}"
    sudo -u "${userConfig.username}" killall cfprefsd >/dev/null 2>&1 || true
    sudo -u "${userConfig.username}" killall Stats >/dev/null 2>&1 || true
  '';
}
