{...}: {
  flake.homeModules.weather = {
    pkgs,
    theme,
    userConfig,
    ...
  }: let
    weatherCodes = {
      "113" = "☀️";
      "116" = "⛅";
      "119" = "☁️";
      "122" = "☁️";
      "143" = "🌫️";
      "176" = "🌦️";
      "179" = "🌨️";
      "182" = "🌧️";
      "185" = "🌧️";
      "200" = "⛈️";
      "227" = "🌨️";
      "230" = "❄️";
      "248" = "🌫️";
      "260" = "🌫️";
      "263" = "🌦️";
      "266" = "🌧️";
      "281" = "🌧️";
      "284" = "🌧️";
      "293" = "🌦️";
      "296" = "🌧️";
      "299" = "🌧️";
      "302" = "🌧️";
      "305" = "🌧️";
      "308" = "🌧️";
      "311" = "🌧️";
      "314" = "🌧️";
      "317" = "🌨️";
      "320" = "🌨️";
      "323" = "🌨️";
      "326" = "🌨️";
      "329" = "❄️";
      "332" = "❄️";
      "335" = "❄️";
      "338" = "❄️";
      "350" = "🌧️";
      "353" = "🌦️";
      "356" = "🌧️";
      "359" = "🌧️";
      "362" = "🌨️";
      "365" = "🌨️";
      "368" = "🌨️";
      "371" = "❄️";
      "374" = "🌨️";
      "377" = "🌨️";
      "386" = "⛈️";
      "389" = "⛈️";
      "392" = "⛈️";
      "395" = "❄️";
    };
    tempColors = {
      frozen = theme.sky;
      cold = theme.blue;
      cool = theme.text;
      mild = theme.green;
      warm = theme.peach;
      hot = theme.red;
    };
    weatherScript = pkgs.writeShellScriptBin "weather" ''
        BAR_MODE=0
        PANEL_MODE=0
        [[ "''${1:-}" == "--bar"   ]] && BAR_MODE=1
        [[ "''${1:-}" == "--panel" ]] && PANEL_MODE=1
        TMPFILE=$(mktemp)
        trap "rm -f $TMPFILE" EXIT
        ${pkgs.curl}/bin/curl -sf "wttr.in/${userConfig.weatherCity}?format=j1" > "$TMPFILE" 2>/dev/null || {
          (( BAR_MODE || PANEL_MODE )) \
            && echo '{"text":"?","tooltip":"unavailable"}' \
            || echo "Could not fetch weather data"
          exit 1
        }
        ${pkgs.python3}/bin/python3 - "$TMPFILE" "$BAR_MODE" "$PANEL_MODE" <<'PYEOF'
      import json, sys
      from datetime import datetime
      codes = ${builtins.toJSON weatherCodes}
      tc    = ${builtins.toJSON tempColors}
      def icon(code): return codes.get(str(code), "🌡️")
      def day_name(date_str):
          d = datetime.strptime(date_str, "%Y-%m-%d")
          diff = (d.date() - datetime.today().date()).days
          if diff == 0: return "Today    "
          if diff == 1: return "Tomorrow "
          return d.strftime("%-d %b     ")[:9]
      with open(sys.argv[1]) as f:
          data = json.load(f)
      bar_mode   = sys.argv[2] == "1"
      panel_mode = sys.argv[3] == "1"
      current = data['current_condition'][0]
      days    = data['weather']
      temp    = current['temp_C']
      feels   = current['FeelsLikeC']
      desc    = current['weatherDesc'][0]['value']
      code    = current['weatherCode']
      humidity = current['humidity']
      wind     = current['windspeedKmph']
      if bar_mode:
          temp_int = int(temp)
          if   temp_int <= 0:  color = tc["frozen"]
          elif temp_int <= 8:  color = tc["cold"]
          elif temp_int <= 15: color = tc["cool"]
          elif temp_int <= 22: color = tc["mild"]
          elif temp_int <= 28: color = tc["warm"]
          else:                color = tc["hot"]
          ic = icon(code)
          print(json.dumps({
              "text":    f"<span color='{color}'>{ic} {temp}°C</span>",
              "tooltip": f"{desc} · feels {feels}°C",
          }))
      elif panel_mode:
        # always show 8 evenly spaced slots across the full day
        all_hourly = days[0]['hourly']  # wttr gives 8 slots: 0,3,6,9,12,15,18,21
        hourly = []
        for h in all_hourly:
            t = int(h['time']) // 100
            hourly.append({
                "time":  f"{t:02d}:00",
                "icon":  icon(h['weatherCode']),
                "temp":  h['tempC'],
                "feels": h['FeelsLikeC'],
                "isPast": t < datetime.now().hour,
            })
        forecast = []
        for day in days:
            forecast.append({
                "date":   day_name(day['date']).strip(),
                "icon":   icon(day['hourly'][4]['weatherCode']),
                "high":   day['maxtempC'],
                "low":    day['mintempC'],
            })
        print(json.dumps({
            "temp":     temp,
            "feels":    feels,
            "desc":     desc,
            "icon":     icon(code),
            "humidity": humidity,
            "wind":     wind,
            "hourly":   hourly,
            "forecast": forecast,
        }))
      else:
          print(f" {icon(code)}  {desc}")
          print(f"    {temp}°C  feels {feels}°C  💧{humidity}%  💨{wind}km/h")
          print()
          print("  Today throughout the day")
          print("  " + "─" * 34)
          for h in days[0]['hourly']:
              t = int(h['time']) // 100
              print(f"  {t:02d}:00  {icon(h['weatherCode'])}  {h['tempC']:>3}°C  feels {h['FeelsLikeC']}°C")
          print()
          print("  Forecast")
          print("  " + "─" * 34)
          for day in days:
              print(f"  {day_name(day['date'])}  {icon(day['hourly'][4]['weatherCode'])}  {day['maxtempC']:>3}° / {day['mintempC']:>3}°")
      PYEOF
    '';
  in {
    home.packages = [weatherScript];
  };
}
