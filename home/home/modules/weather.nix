{pkgs, ...}: let
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

  weatherScript = pkgs.writeShellScriptBin "weather" ''
        TMPFILE=$(mktemp)
        trap "rm -f $TMPFILE" EXIT
        ${pkgs.curl}/bin/curl -sf "wttr.in/Novi+Sad?format=j1" > "$TMPFILE" || {
          echo "Could not fetch weather data"
          exit 1
        }
        ${pkgs.python3}/bin/python3 - "$TMPFILE" <<'PYEOF'
    import json, sys
    from datetime import datetime
    codes = ${builtins.toJSON weatherCodes}
    def icon(code): return codes.get(str(code), "🌡️")
    def day_name(date_str):
        d = datetime.strptime(date_str, "%Y-%m-%d")
        diff = (d.date() - datetime.today().date()).days
        if diff == 0: return "Today    "
        if diff == 1: return "Tomorrow "
        return d.strftime("%-d %b     ")[:9]
    with open(sys.argv[1]) as f:
        data = json.load(f)['data']
    current = data['current_condition'][0]
    days = data['weather']
    temp = current['temp_C']
    feels = current['FeelsLikeC']
    desc = current['weatherDesc'][0]['value']
    code = current['weatherCode']
    humidity = current['humidity']
    wind = current['windspeedKmph']
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

  wttrbarScript = pkgs.writeShellScriptBin "wttrbar-weather" ''
        TMPFILE=$(mktemp)
        trap "rm -f $TMPFILE" EXIT
        ${pkgs.curl}/bin/curl -sf "wttr.in/Novi+Sad?format=j1" > "$TMPFILE" 2>/dev/null || {
          echo '{"text":"?","tooltip":"unavailable"}'
          exit 0
        }
        ${pkgs.python3}/bin/python3 - "$TMPFILE" <<'PYEOF'
    import json, sys
    codes = ${builtins.toJSON weatherCodes}
    def icon(code): return codes.get(str(code), "🌡️")
    with open(sys.argv[1]) as f:
        data = json.load(f)['data']
    current = data['current_condition'][0]
    temp = current['temp_C']
    feels = current['FeelsLikeC']
    code = current['weatherCode']
    ic = icon(code)
    desc = current['weatherDesc'][0]['value']
    temp_int = int(temp)
    if temp_int <= 0:
        color = "#89dceb"
    elif temp_int <= 8:
        color = "#89b4fa"
    elif temp_int <= 15:
        color = "#cdd6f4"
    elif temp_int <= 22:
        color = "#a6e3a1"
    elif temp_int <= 28:
        color = "#fab387"
    else:
        color = "#f38ba8"
    print(json.dumps({"text": f"<span color='{color}'>{ic} {temp}°C</span>", "tooltip": f"{desc} · feels {feels}°C"}))
    PYEOF
  '';
in {
  home.packages = [weatherScript wttrbarScript];
}
