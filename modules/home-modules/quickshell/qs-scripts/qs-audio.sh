{pkgs}: ''
    ${pkgs.pipewire}/bin/pw-dump 2>/dev/null | \
    ${pkgs.python3}/bin/python3 - <<'PYEOF'
  import json, sys, subprocess

  def wpctl_volume(id):
      try:
          out = subprocess.check_output(["wpctl", "get-volume", str(id)], text=True).strip()
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
      try:
          if type_ == "sink":
              name = subprocess.check_output(
                  ["pactl", "get-default-sink"], text=True
              ).strip()
          else:
              name = subprocess.check_output(
                  ["pactl", "get-default-source"], text=True
              ).strip()
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
''
