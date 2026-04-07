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
      playerctl
      quickshell
      wl-clipboard
      cliphist
      awww

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
      (pkgs.writeShellScriptBin "qs-cava-bar" ''
        exec ${pkgs.cava}/bin/cava -p ${userConfig.homeDirectory}/.config/cava/cava-bar.conf
      '')
      (pkgs.writeShellScriptBin "qs-audio" ''
          ${pkgs.pipewire}/bin/pw-dump 2>/dev/null | \
          ${pkgs.python3}/bin/python3 - <<'PYEOF'
        import json, sys, subprocess

        def wpctl_volume(id):
            try:
                out = subprocess.check_output(["wpctl", "get-volume", str(id)], text=True).strip()
                # output is like "Volume: 0.75" or "Volume: 0.75 [MUTED]"
                parts = out.split()
                vol = float(parts[1])
                muted = "[MUTED]" in out
                return vol, muted
            except:
                return 0.0, False

        def pactl_apps():
            try:
                out = subprocess.check_output(
                    ["pactl", "-f", "json", "list", "sink-inputs"],
                    text=True
                )
                inputs = json.loads(out)
                apps = []
                for i in inputs:
                    idx = i.get("index", 0)
                    props = i.get("properties", {})
                    name = (
                        props.get("application.name")
                        or props.get("media.name")
                        or "Unknown"
                    )
                    vol_channels = i.get("volume", {})
                    if vol_channels:
                        first = list(vol_channels.values())[0]
                        vol = first.get("value_percent", "0%").rstrip("%")
                        vol = int(vol) / 100.0
                    else:
                        vol = 0.0
                    muted = i.get("mute", False)
                    apps.append({
                        "index": idx,
                        "name": name,
                        "volume": round(vol, 3),
                        "muted": muted,
                    })
                return apps
            except:
                return []

        def wpctl_default(type_):
            # type_ is "sink" or "source"
            # use pactl to get the default name, then wpctl status to get id
            try:
                if type_ == "sink":
                    name = subprocess.check_output(
                        ["pactl", "get-default-sink"], text=True
                    ).strip()
                else:
                    name = subprocess.check_output(
                        ["pactl", "get-default-source"], text=True
                    ).strip()
                # get friendly description
                key = "sinks" if type_ == "sink" else "sources"
                out = subprocess.check_output(
                    ["pactl", "-f", "json", "list", key], text=True
                )
                items = json.loads(out)
                desc = name
                for item in items:
                    if item.get("name") == name:
                        desc = item.get("description", name)
                        break
                return name, desc
            except:
                return "", ""

        out_name, out_desc = wpctl_default("sink")
        in_name, in_desc = wpctl_default("source")

        out_vol, out_muted = wpctl_volume("@DEFAULT_AUDIO_SINK@")
        in_vol, in_muted = wpctl_volume("@DEFAULT_AUDIO_SOURCE@")

        apps = pactl_apps()

        print(json.dumps({
            "output": {
                "name": out_name,
                "desc": out_desc,
                "volume": round(out_vol, 3),
                "muted": out_muted,
            },
            "input": {
                "name": in_name,
                "desc": in_desc,
                "volume": round(in_vol, 3),
                "muted": in_muted,
            },
            "apps": apps,
        }))
        PYEOF
      '')
      (pkgs.writeShellScriptBin "qs-audio-set" ''
        TYPE="$1"
        if [[ "$TYPE" == "sink" ]]; then
          wpctl set-volume @DEFAULT_AUDIO_SINK@ "$2"
        elif [[ "$TYPE" == "source" ]]; then
          wpctl set-volume @DEFAULT_AUDIO_SOURCE@ "$2"
        elif [[ "$TYPE" == "app" ]]; then
          pactl set-sink-input-volume "$2" "$3%"
        fi
      '')

      # ── Clipboard helpers ──────────────────────────────────────────────────
      (pkgs.writeShellScriptBin "qs-clip-copy-text" ''
        printf '%s' "$1" | cliphist decode | wl-copy
      '')
      (pkgs.writeShellScriptBin "qs-clip-copy-img" ''
        printf '%s' "$1" | cliphist decode | wl-copy
      '')
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
    xdg.configFile."quickshell/bar/DateTimePanel.qml".source = ./bar/DateTimePanel.qml;
    xdg.configFile."cava/cava-bar.conf".text = ''
      [general]
      bars = 20
      sleep_timer = 5

      [input]
      method = pipewire

      [output]
      method = raw
      raw_target = /dev/stdout
      data_format = ascii
      ascii_max_range = 15
    '';
    xdg.configFile."quickshell/bar/MediaAudioPanel.qml".source = ./bar/MediaAudioPanel.qml;

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
