{...}: {
  flake.homeModules.media = {
    pkgs,
    theme,
    ...
  }: let
    pythonEnv = pkgs.python3.withPackages (ps: [ps.pygobject3]);

    # ── media-popup ───────────────────────────────────────────────────────────────
    mediaPopupPy = pkgs.writeText "media-popup.py" ''
      import gi, os, atexit, subprocess, urllib.request, urllib.parse
      import threading, tempfile, struct, time, shutil
      gi.require_version("Gtk", "3.0")
      gi.require_version("GdkPixbuf", "2.0")
      from gi.repository import Gtk, Gdk, GdkPixbuf, GLib, Pango
      import cairo

      MAUVE        = "${theme.mauve}"
      TEXT         = "${theme.text}"
      SUBTEXT0     = "${theme.subtext0}"
      OVERLAY0     = "${theme.overlay0}"
      CRUST_RGB    = "${theme.crustRgb}"
      SURFACE0_RGB = "${theme.surface0Rgb}"
      MAUVE_RGB    = "${theme.mauveRgb}"

      WPCTL     = "${pkgs.wireplumber}/bin/wpctl"
      PLAYERCTL = "${pkgs.playerctl}/bin/playerctl"
      CAVA      = "${pkgs.cava}/bin/cava"

      PIDFILE = os.path.join(os.environ.get("XDG_RUNTIME_DIR", "/tmp"), "media-popup.pid")
      atexit.register(lambda: os.path.exists(PIDFILE) and os.unlink(PIDFILE))

      ART_W        = 280
      ART_H        = 158
      VIZ_H        = 48
      N_BARS       = 24
      POLL_MS      = 2000
      CMD_DEBOUNCE = 0.3
      VOL_DEBOUNCE = 60

      ICON_PREV    = chr(0xf04ae)
      ICON_PLAY    = chr(0xf040a)
      ICON_PAUSE   = chr(0xf03e4)
      ICON_NEXT    = chr(0xf04ad)
      ICON_VOL_LO  = chr(0xf057f)
      ICON_VOL_MID = chr(0xf0580)
      ICON_VOL_HI  = chr(0xf057e)

      def vol_icon(v):
          return ICON_VOL_LO if v < 0.33 else ICON_VOL_MID if v < 0.66 else ICON_VOL_HI

      def hex_to_rgb(h):
          h = h.lstrip("#")
          return tuple(int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))

      MAUVE_C = hex_to_rgb(MAUVE)

      _placeholder = None
      def placeholder_art():
          global _placeholder
          if _placeholder is None:
              pb = GdkPixbuf.Pixbuf.new(GdkPixbuf.Colorspace.RGB, False, 8, ART_W, ART_H)
              pb.fill(0x313244FF)
              _placeholder = pb
          return _placeholder

      _art_cache = {}
      _art_lock  = threading.Lock()

      def fetch_art_bytes(url):
          if not url:
              return None
          with _art_lock:
              if url in _art_cache:
                  return _art_cache[url]
          data = None
          try:
              if url.startswith("file://"):
                  path = urllib.parse.unquote(url[7:])
                  if os.path.exists(path):
                      with open(path, "rb") as f:
                          data = f.read()
              else:
                  req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
                  with urllib.request.urlopen(req, timeout=5) as resp:
                      data = resp.read()
          except Exception:
              data = None
          with _art_lock:
              _art_cache[url] = data
          return data

      def pixbuf_from_bytes(data):
          if not data:
              return None
          try:
              loader = GdkPixbuf.PixbufLoader()
              loader.write(data)
              loader.close()
              src = loader.get_pixbuf()
              if src is None:
                  return None
              return src.scale_simple(ART_W, ART_H, GdkPixbuf.InterpType.BILINEAR)
          except Exception:
              return None

      def get_media_info():
          try:
              r = subprocess.run(
                  [PLAYERCTL, "metadata", "--format",
                   "{{title}}\n{{artist}}\n{{status}}\n{{mpris:artUrl}}"],
                  capture_output=True, text=True, timeout=2,
              )
              parts = r.stdout.split("\n")
              title  = parts[0].strip() if len(parts) > 0 else ""
              artist = parts[1].strip() if len(parts) > 1 else ""
              status = parts[2].strip() if len(parts) > 2 else "Stopped"
              art    = parts[3].strip() if len(parts) > 3 else ""
              return title or "No media", artist, status or "Stopped", art
          except Exception:
              return "No media", "", "Stopped", ""

      def get_volume():
          try:
              r = subprocess.run(
                  [WPCTL, "get-volume", "@DEFAULT_AUDIO_SINK@"],
                  capture_output=True, text=True, timeout=1,
              )
              parts = r.stdout.strip().split()
              return float(parts[1]) if len(parts) >= 2 else 1.0
          except Exception:
              return 1.0

      def set_volume(v):
          try:
              subprocess.Popen(
                  [WPCTL, "set-volume", "@DEFAULT_AUDIO_SINK@", f"{v:.2f}"],
                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
              )
          except Exception:
              pass

      class CavaReader:
          def __init__(self, n_bars, callback):
              self._n       = n_bars
              self._cb      = callback
              self._proc    = None
              self._tmpdir  = None
              self._running = False

          def start(self):
              self._tmpdir = tempfile.mkdtemp()
              fifo = os.path.join(self._tmpdir, "cava.fifo")
              os.mkfifo(fifo)
              cfg = os.path.join(self._tmpdir, "cava.cfg")
              with open(cfg, "w") as f:
                  f.write(
                      f"[general]\nbars = {self._n}\n"
                      f"[input]\nmethod = pipewire\n"
                      f"[output]\nmethod = raw\nraw_target = {fifo}\n"
                      f"data_format = binary\nbit_format = 16bit\n"
                  )
              self._running = True
              self._proc = subprocess.Popen(
                  [CAVA, "-p", cfg],
                  stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
              )
              threading.Thread(target=self._read, args=(fifo,), daemon=True).start()

          def _read(self, fifo):
              chunk = self._n * 2
              try:
                  with open(fifo, "rb") as f:
                      while self._running:
                          data = f.read(chunk)
                          if len(data) < chunk:
                              break
                          vals = struct.unpack(f"{self._n}H", data)
                          GLib.idle_add(self._cb, [v / 65535.0 for v in vals])
              except Exception:
                  pass

          def stop(self):
              self._running = False
              if self._proc:
                  self._proc.terminate()
              if self._tmpdir:
                  shutil.rmtree(self._tmpdir, ignore_errors=True)

      CSS = f"""
      window {{ background-color: transparent; }}
      .card {{
          background-color: rgba({CRUST_RGB}, 0.97);
          border-radius: 16px;
      }}
      .meta-box {{ padding: 10px 16px 4px 16px; }}
      .ctrl-box {{ padding: 6px 16px 4px 16px; }}
      .vol-box  {{ padding: 2px 20px 12px 20px; }}
      .track-title {{
          color: {TEXT};
          font-family: "JetBrainsMono Nerd Font";
          font-size: 13px;
          font-weight: bold;
      }}
      .track-artist {{
          color: {SUBTEXT0};
          font-family: "JetBrainsMono Nerd Font";
          font-size: 11px;
      }}
      .ctrl-btn {{
          background-color: transparent;
          color: {OVERLAY0};
          border: none;
          padding: 4px 10px;
          font-family: "JetBrainsMono Nerd Font";
          font-size: 15px;
      }}
      .ctrl-btn:hover  {{ background-color: rgba({MAUVE_RGB}, 0.15); color: {MAUVE}; }}
      .ctrl-btn:active {{ background-color: rgba({MAUVE_RGB}, 0.25); color: {MAUVE}; }}
      .vol-icon {{
          color: {OVERLAY0};
          font-family: "JetBrainsMono Nerd Font";
          font-size: 13px;
          margin-right: 6px;
      }}
      scale trough {{
          background-color: rgba({SURFACE0_RGB}, 0.9);
          border-radius: 4px;
          min-height: 4px;
          border: none;
      }}
      scale highlight {{
          background-color: {MAUVE};
          border-radius: 4px;
          min-height: 4px;
          border: none;
      }}
      scale slider {{
          background-color: {MAUVE};
          border-radius: 50%;
          min-width: 12px;
          min-height: 12px;
          border: none;
      }}
      scale slider:hover {{ background-color: {TEXT}; }}
      """.encode()

      class MediaPopup(Gtk.Window):
          def __init__(self):
              super().__init__()
              GLib.set_prgname("media-popup")
              self.set_title("media-popup")
              self.set_decorated(False)
              self.set_resizable(False)
              self.set_skip_taskbar_hint(True)
              self.set_skip_pager_hint(True)
              self.set_keep_above(True)
              self.set_app_paintable(True)
              v = self.get_screen().get_rgba_visual()
              if v:
                  self.set_visual(v)

              provider = Gtk.CssProvider()
              provider.load_from_data(CSS)
              Gtk.StyleContext.add_provider_for_screen(
                  Gdk.Screen.get_default(), provider,
                  Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
              )

              self._viz_bars       = [0.0] * N_BARS
              self._refreshing     = False
              self._last_art_url   = None
              self._last_art_bytes = None
              self._last_pixbuf    = None
              self._cmd_ts         = 0.0
              self._vol_timer      = None
              self._vol_updating   = False

              self._cava = CavaReader(N_BARS, self._on_bars)
              self._build()

              self.connect("key-press-event", self._on_key)
              self.connect("destroy", self._on_destroy)

              self._schedule_refresh()
              GLib.timeout_add(POLL_MS, self._tick)
              self._cava.start()

          def _on_destroy(self, *_):
              self._cava.stop()
              Gtk.main_quit()

          def _on_key(self, _w, event):
              if event.keyval == Gdk.KEY_Escape:
                  self.destroy()

          def _tick(self):
              if not self.get_visible():
                  return False
              self._schedule_refresh()
              return True

          def _schedule_refresh(self):
              if self._refreshing:
                  return
              self._refreshing = True
              threading.Thread(target=self._bg_refresh, daemon=True).start()

          def _bg_refresh(self):
              title, artist, status, art_url = get_media_info()
              vol = get_volume()
              if art_url != self._last_art_url:
                  art_bytes = fetch_art_bytes(art_url)
                  self._last_art_url   = art_url
                  self._last_art_bytes = art_bytes
                  self._last_pixbuf    = None
              else:
                  art_bytes = self._last_art_bytes
              GLib.idle_add(self._apply_refresh, title, artist, status, art_bytes, vol)

          def _apply_refresh(self, title, artist, status, art_bytes, vol):
              self._refreshing = False
              self._title_lbl.set_text(title)
              self._artist_lbl.set_text(artist)
              self._play_btn.set_label(ICON_PAUSE if status == "Playing" else ICON_PLAY)
              if self._last_pixbuf is None:
                  self._last_pixbuf = pixbuf_from_bytes(art_bytes)
              self._art.set_from_pixbuf(
                  self._last_pixbuf if self._last_pixbuf else placeholder_art()
              )
              v = max(0.0, min(1.0, float(vol)))
              self._vol_updating = True
              self._vol_slider.set_value(v)
              self._vol_updating = False
              self._vol_icon.set_text(vol_icon(v))
              return False

          def _cmd(self, cmd):
              now = time.monotonic()
              if now - self._cmd_ts < CMD_DEBOUNCE:
                  return
              self._cmd_ts = now
              try:
                  subprocess.Popen(
                      [PLAYERCTL, cmd],
                      stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                  )
              except Exception:
                  pass
              GLib.timeout_add(400, self._schedule_refresh)

          def _on_bars(self, bars):
              self._viz_bars = bars
              self._viz_area.queue_draw()

          def _on_volume_changed(self, slider):
              if self._vol_updating:
                  return
              v = slider.get_value()
              self._vol_icon.set_text(vol_icon(v))
              if self._vol_timer is not None:
                  GLib.source_remove(self._vol_timer)
              self._vol_timer = GLib.timeout_add(VOL_DEBOUNCE, self._apply_volume, v)

          def _apply_volume(self, v):
              set_volume(v)
              self._vol_timer = None
              return False

          def _draw_viz(self, widget, cr):
              w = widget.get_allocated_width()
              h = widget.get_allocated_height()
              bars = self._viz_bars
              n = len(bars)
              if not n:
                  return
              gap   = 3
              bar_w = (w - gap * (n - 1)) / n
              cr.set_source_rgba(0, 0, 0, 0)
              cr.paint()
              for i, v in enumerate(bars):
                  x  = i * (bar_w + gap)
                  bh = max(2, v * h)
                  y  = h - bh
                  r  = min(bar_w / 2, 3)
                  grad = cairo.LinearGradient(x, y, x, h)
                  grad.add_color_stop_rgba(0, *MAUVE_C, 0.9)
                  grad.add_color_stop_rgba(1, *MAUVE_C, 0.4)
                  cr.set_source(grad)
                  cr.new_sub_path()
                  cr.arc(x + bar_w - r, y + r, r, -1.5708, 0)
                  cr.arc(x + bar_w - r, h - r,  r, 0,       1.5708)
                  cr.arc(x + r,         h - r,  r, 1.5708,  3.1416)
                  cr.arc(x + r,         y + r,  r, 3.1416,  4.7124)
                  cr.close_path()
                  cr.fill()

          def _make_btn(self, icon):
              b = Gtk.Button(label=icon)
              b.get_style_context().add_class("ctrl-btn")
              b.set_relief(Gtk.ReliefStyle.NONE)
              b.set_can_focus(False)
              b.set_size_request(60, 32)
              return b

          def _build(self):
              card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=0)
              card.get_style_context().add_class("card")

              self._art = Gtk.Image()
              self._art.set_size_request(ART_W, ART_H)
              self._art.set_margin_top(12)
              self._art.set_margin_start(12)
              self._art.set_margin_end(12)
              self._art.set_from_pixbuf(placeholder_art())
              card.pack_start(self._art, False, False, 0)

              self._viz_area = Gtk.DrawingArea()
              self._viz_area.set_size_request(ART_W, VIZ_H)
              self._viz_area.set_margin_start(12)
              self._viz_area.set_margin_end(12)
              self._viz_area.connect("draw", self._draw_viz)
              card.pack_start(self._viz_area, False, False, 0)

              meta = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
              meta.get_style_context().add_class("meta-box")
              self._title_lbl = Gtk.Label(label="No media")
              self._title_lbl.get_style_context().add_class("track-title")
              self._title_lbl.set_halign(Gtk.Align.START)
              self._title_lbl.set_ellipsize(Pango.EllipsizeMode.END)
              self._title_lbl.set_max_width_chars(32)
              self._artist_lbl = Gtk.Label(label="")
              self._artist_lbl.get_style_context().add_class("track-artist")
              self._artist_lbl.set_halign(Gtk.Align.START)
              self._artist_lbl.set_ellipsize(Pango.EllipsizeMode.END)
              self._artist_lbl.set_max_width_chars(32)
              meta.pack_start(self._title_lbl,  False, False, 0)
              meta.pack_start(self._artist_lbl, False, False, 0)
              card.pack_start(meta, False, False, 0)

              ctrl_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
              ctrl_box.get_style_context().add_class("ctrl-box")
              ctrl_box.set_halign(Gtk.Align.CENTER)
              ctrl_box.set_homogeneous(True)

              prev_btn       = self._make_btn(ICON_PREV)
              self._play_btn = self._make_btn(ICON_PLAY)
              next_btn       = self._make_btn(ICON_NEXT)

              prev_btn.connect("clicked",       lambda *_: self._cmd("previous"))
              self._play_btn.connect("clicked", lambda *_: self._cmd("play-pause"))
              next_btn.connect("clicked",       lambda *_: self._cmd("next"))

              for btn in [prev_btn, self._play_btn, next_btn]:
                  ctrl_box.pack_start(btn, False, False, 0)
              card.pack_start(ctrl_box, False, False, 0)

              vol_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
              vol_box.get_style_context().add_class("vol-box")
              self._vol_icon = Gtk.Label(label=ICON_VOL_HI)
              self._vol_icon.get_style_context().add_class("vol-icon")
              vol_box.pack_start(self._vol_icon, False, False, 0)
              self._vol_slider = Gtk.Scale.new_with_range(
                  Gtk.Orientation.HORIZONTAL, 0.0, 1.0, 0.02)
              self._vol_slider.set_draw_value(False)
              self._vol_slider.set_can_focus(False)
              self._vol_slider.set_hexpand(True)
              self._vol_slider.connect("value-changed", self._on_volume_changed)
              vol_box.pack_start(self._vol_slider, True, True, 0)
              card.pack_start(vol_box, False, False, 0)

              self.add(card)

      MediaPopup().show_all()
      Gtk.main()
    '';

    mediaPopup = pkgs.stdenv.mkDerivation {
      name = "media-popup";
      dontUnpack = true;
      dontBuild = true;
      nativeBuildInputs = [
        pkgs.gobject-introspection
        pkgs.wrapGAppsHook3
      ];
      buildInputs = [
        pkgs.gtk3
        pkgs.gdk-pixbuf
        pkgs.pango
        pkgs.atk
      ];
      installPhase = ''
        mkdir -p $out/bin
        echo "#!${pythonEnv}/bin/python3" > $out/bin/media-popup
        cat ${mediaPopupPy} >> $out/bin/media-popup
        chmod +x $out/bin/media-popup
      '';
    };

    mediaToggleScript = pkgs.writeShellScriptBin "media-popup-toggle" ''
      PIDFILE="''${XDG_RUNTIME_DIR:-/tmp}/media-popup.pid"

      if [ -f "$PIDFILE" ]; then
        PID=$(cat "$PIDFILE")
        if kill -0 "$PID" 2>/dev/null; then
          kill "$PID"
          rm -f "$PIDFILE"
          exit 0
        fi
        rm -f "$PIDFILE"
      fi

      ${mediaPopup}/bin/media-popup &
      echo $! > "$PIDFILE"
    '';
  in {
    home.packages = [
      pkgs.playerctl
      pkgs.wireplumber
      mediaToggleScript
      mediaPopup
    ];
  };
}
