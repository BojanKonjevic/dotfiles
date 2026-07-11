{
  pkgs,
  lib,
  ...
}: let
  bundleId = "cc.ffitch.shottr";

  settingsPlist = pkgs.writeText "shottr-settings.plist" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>KeyboardShortcuts_area</key>
      <string>{"carbonKeyCode":19,"carbonModifiers":768}</string>
      <key>KeyboardShortcuts_fullscreen</key>
      <string>{"carbonModifiers":768,"carbonKeyCode":18}</string>
      <key>KeyboardShortcuts_ocr</key>
      <string>{"carbonModifiers":6400,"carbonKeyCode":31}</string>

      <key>afterGrabCopy</key>
      <true/>
      <key>afterGrabSave</key>
      <true/>
      <key>afterGrabShow</key>
      <true/>
      <key>allowTelemetry</key>
      <true/>
      <key>altZoomDirection</key>
      <false/>
      <key>alwaysOnTop</key>
      <false/>
      <key>areaCaptureMode</key>
      <string>editor</string>
      <key>areaCustomGrabber</key>
      <false/>
      <key>captureCursor</key>
      <string>auto</string>
      <key>cmdQAction</key>
      <string>close</string>
      <key>colorFormat</key>
      <string>HEX</string>
      <key>contrastType</key>
      <string>wcag2</string>
      <key>copyOnEsc</key>
      <true/>
      <key>customBackdropColor</key>
      <string>#6080A0</string>
      <key>customGradFrom</key>
      <string>#221448</string>
      <key>customGradTo</key>
      <string>#919BD2</string>
      <key>defaultColor</key>
      <string>#FF0C01</string>
      <key>defaultFolder</key>
      <string>/Users/bojan/Pictures/Screenshots</string>
      <key>downscaleOnSave</key>
      <false/>
      <key>enableMagicMouseZoom</key>
      <false/>
      <key>expandableCanvas</key>
      <true/>
      <key>notificationType</key>
      <string>custom</string>
      <key>ocrRemoveBreaks</key>
      <false/>
      <key>preferLargeWindow</key>
      <true/>
      <key>primaryOCRLang</key>
      <string>en-US</string>
      <key>realPixels</key>
      <false/>
      <key>saveFormat</key>
      <string>Auto</string>
      <key>saveOnEsc</key>
      <false/>
      <key>scrollingManualEnabled</key>
      <false/>
      <key>scrollingMax</key>
      <integer>20000</integer>
      <key>scrollingReverseAutoscroll</key>
      <false/>
      <key>scrollingSpeed</key>
      <integer>2</integer>
      <key>snappingMode</key>
      <integer>2</integer>
      <key>thumbnailClosing</key>
      <string>manual</string>
      <key>uploadMode</key>
      <string>none</string>
      <key>windowShadow</key>
      <string>transparent</string>
      <key>windowSolidColor</key>
      <string>#404448</string>
    </dict>
    </plist>
  '';
in {
  home.packages = [pkgs.shottr];

  home.activation.shottrSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    echo "Applying Shottr settings..." >&2
    /usr/bin/defaults import "${bundleId}" "${settingsPlist}"
  '';
}
