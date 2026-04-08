{userConfig}: ''
  awww img "$1" \
    --transition-type wipe \
    --transition-angle 30 \
    --transition-duration 0.8 \
    --transition-fps 60
  ln -sf "$1" "${userConfig.wallpaperDir}/wall.jpg"
''
