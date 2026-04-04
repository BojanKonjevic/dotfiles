{...}: {
  flake.homeModules.quickshell = {
    quickshell,
    theme,
    pkgs,
    userConfig,
    ...
  }: let
    coloursQml = ''
      pragma Singleton
      import QtQuick

      QtObject {
        readonly property color base:      "${theme.base}"
        readonly property color mantle:    "${theme.mantle}"
        readonly property color crust:     "${theme.crust}"
        readonly property color surface0:  "${theme.surface0}"
        readonly property color surface1:  "${theme.surface1}"
        readonly property color surface2:  "${theme.surface2}"
        readonly property color overlay0:  "${theme.overlay0}"
        readonly property color overlay1:  "${theme.overlay1}"
        readonly property color overlay2:  "${theme.overlay2}"
        readonly property color subtext0:  "${theme.subtext0}"
        readonly property color subtext1:  "${theme.subtext1}"
        readonly property color text:      "${theme.text}"
        readonly property color rosewater: "${theme.rosewater}"
        readonly property color flamingo:  "${theme.flamingo}"
        readonly property color pink:      "${theme.pink}"
        readonly property color mauve:     "${theme.mauve}"
        readonly property color red:       "${theme.red}"
        readonly property color maroon:    "${theme.maroon}"
        readonly property color peach:     "${theme.peach}"
        readonly property color yellow:    "${theme.yellow}"
        readonly property color green:     "${theme.green}"
        readonly property color teal:      "${theme.teal}"
        readonly property color sky:       "${theme.sky}"
        readonly property color sapphire:  "${theme.sapphire}"
        readonly property color blue:      "${theme.blue}"
        readonly property color lavender:  "${theme.lavender}"

        readonly property string fontFamily: "${theme.fontName}"
      }
    '';
  in {
    home.packages = with pkgs; [
      quickshell
      wl-clipboard
      cliphist
      awww

      (pkgs.writeShellScriptBin "qs-clip-copy-text" ''
        printf '%s' "$1" | cliphist decode | wl-copy
      '')
      (pkgs.writeShellScriptBin "qs-clip-copy-img" ''
        printf '%s' "$1" | cliphist decode | wl-copy
      '')

      # ── Bar helpers ────────────────────────────────────────────────────────
      (pkgs.writeShellScriptBin "qs-cpu" ''
        awk '
          NR==1 { u=$2+$4; t=$2+$3+$4+$5 }
          NR==2 { print int(($2+$4-u)/($2+$3+$4+$5-t)*100) }
        ' <(grep "^cpu " /proc/stat) <(sleep 0.3; grep "^cpu " /proc/stat)
      '')
      (pkgs.writeShellScriptBin "qs-mem" ''
        awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{print int((t-a)/t*100)}' /proc/meminfo
      '')
      (pkgs.writeShellScriptBin "qs-net" ''
        nmcli -t -f TYPE,STATE dev status 2>/dev/null \
          | awk -F: '$2=="connected" {print $1; exit}'
      '')
      (pkgs.writeShellScriptBin "qs-mic" ''
        wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -c MUTED
      '')

      # ── Clipboard helpers ──────────────────────────────────────────────────
      (pkgs.writeShellScriptBin "qs-clip-clear-text" ''
        cliphist list | while IFS=$'\t' read -r id content; do
          [[ "$content" == *"[[ binary data"* ]] && continue
          printf '%s\t%s' "$id" "$content" | cliphist delete
        done
      '')
      (pkgs.writeShellScriptBin "qs-clip-clear-img" ''
        cliphist list | while IFS=$'\t' read -r id content; do
          [[ "$content" == *"[[ binary data"* ]] || continue
          printf '%s\t%s' "$id" "$content" | cliphist delete
        done
      '')
      (pkgs.writeShellScriptBin "qs-clip-images" ''
        CACHE_DIR="''${XDG_CACHE_HOME:-$HOME/.cache}/cliphist-qs"
        mkdir -p "$CACHE_DIR"
        mapfile -t live_ids < <(cliphist list | awk -F'\t' '{print $1}')
        for f in "$CACHE_DIR"/*.png; do
          [[ -f "$f" ]] || continue
          id="''${f##*/}"; id="''${id%.png}"
          printf '%s\n' "''${live_ids[@]}" | grep -qx "$id" || rm -f "$f"
        done
        while IFS=$'\t' read -r id content; do
          [[ "$content" == *"[[ binary data"* ]] || continue
          img="$CACHE_DIR/''${id}.png"
          if [[ ! -s "$img" ]]; then
            printf '%s\t%s' "$id" "$content" | cliphist decode > "$img" 2>/dev/null
          fi
          [[ -s "$img" ]] || continue
          printf '{"id":"%s","content":"%s","path":"file://%s"}\n' "$id" "$content" "$img"
        done < <(cliphist list)
      '')

      # ── Wallpaper helpers ──────────────────────────────────────────────────
      (pkgs.writeShellScriptBin "qs-wallpapers" ''
        find ${userConfig.wallpaperDir} -maxdepth 1 -type f \
          \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) \
          | sort \
          | while read -r f; do
              printf '{"name":"%s","path":"file://%s"}\n' "$(basename "$f")" "$f"
            done
      '')
      (pkgs.writeShellScriptBin "qs-setwall" ''
        awww img "$1" \
          --transition-type wipe \
          --transition-angle 30 \
          --transition-duration 0.8 \
          --transition-fps 60
        ln -sf "$1" "${userConfig.wallpaperDir}/wall.jpg"
      '')
    ];

    # ── Bar ───────────────────────────────────────────────────────────────────
    xdg.configFile."quickshell/bar/Colours.qml".text = coloursQml;
    xdg.configFile."quickshell/bar/qmldir".source = ./bar/qmldir;
    xdg.configFile."quickshell/bar/shell.qml".source = ./bar/shell.qml;
    xdg.configFile."quickshell/bar/Bar.qml".source = ./bar/Bar.qml;
    xdg.configFile."quickshell/bar/WorkspaceButton.qml".source = ./bar/WorkspaceButton.qml;
    xdg.configFile."quickshell/bar/NotificationPopups.qml".source = ./bar/NotificationPopups.qml;
    xdg.configFile."quickshell/bar/NotificationPopup.qml".source = ./bar/NotificationPopup.qml;
    xdg.configFile."quickshell/bar/PowerPanel.qml".source = ./bar/PowerPanel.qml;
    xdg.configFile."quickshell/bar/PowerPanelButton.qml".source = ./bar/PowerPanelButton.qml;

    # ── Launcher ──────────────────────────────────────────────────────────────
    xdg.configFile."quickshell/launcher/Colours.qml".text = coloursQml;
    xdg.configFile."quickshell/launcher/qmldir".source = ./launcher/qmldir;
    xdg.configFile."quickshell/launcher/shell.qml".source = ./launcher/shell.qml;
    xdg.configFile."quickshell/launcher/Launcher.qml".source = ./launcher/Launcher.qml;
    xdg.configFile."quickshell/launcher/AppEntry.qml".source = ./launcher/AppEntry.qml;

    # ── Clipboard text ────────────────────────────────────────────────────────
    xdg.configFile."quickshell/clip-text/Colours.qml".text = coloursQml;
    xdg.configFile."quickshell/clip-text/qmldir".source = ./clip-text/qmldir;
    xdg.configFile."quickshell/clip-text/shell.qml".source = ./clip-text/shell.qml;
    xdg.configFile."quickshell/clip-text/ClipText.qml".source = ./clip-text/ClipText.qml;

    # ── Clipboard image ───────────────────────────────────────────────────────
    xdg.configFile."quickshell/clip-img/Colours.qml".text = coloursQml;
    xdg.configFile."quickshell/clip-img/qmldir".source = ./clip-img/qmldir;
    xdg.configFile."quickshell/clip-img/shell.qml".source = ./clip-img/shell.qml;
    xdg.configFile."quickshell/clip-img/ClipImage.qml".source = ./clip-img/ClipImage.qml;

    # ── Wallpaper ─────────────────────────────────────────────────────────────
    xdg.configFile."quickshell/wallpaper/Colours.qml".text = coloursQml;
    xdg.configFile."quickshell/wallpaper/qmldir".source = ./wallpaper/qmldir;
    xdg.configFile."quickshell/wallpaper/shell.qml".source = ./wallpaper/shell.qml;
    xdg.configFile."quickshell/wallpaper/WallpaperPicker.qml".source = ./wallpaper/WallpaperPicker.qml;
  };
}
