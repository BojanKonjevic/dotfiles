{pkgs, ...}: {
  home.packages = [pkgs.aerospace];

  xdg.configFile."aerospace/aerospace.toml".text = ''
    [gaps]
    inner.horizontal = 8
    inner.vertical = 8
    outer.left = 8
    outer.right = 8
    outer.top = 8
    outer.bottom = 8

    [mode.main.binding]
    alt-h = "focus --direction left"
    alt-j = "focus --direction down"
    alt-k = "focus --direction up"
    alt-l = "focus --direction right"
    alt-shift-h = "move --direction left"
    alt-shift-j = "move --direction down"
    alt-shift-k = "move --direction up"
    alt-shift-l = "move --direction right"
    alt-1 = "workspace 1"
    alt-2 = "workspace 2"
    alt-3 = "workspace 3"
    alt-4 = "workspace 4"
    alt-5 = "workspace 5"
    alt-6 = "workspace 6"
    alt-7 = "workspace 7"
    alt-8 = "workspace 8"
    alt-9 = "workspace 9"
    alt-0 = "workspace 10"
    alt-shift-1 = "move --to-workspace 1"
    alt-shift-2 = "move --to-workspace 2"
    alt-shift-3 = "move --to-workspace 3"
    alt-shift-4 = "move --to-workspace 4"
    alt-shift-5 = "move --to-workspace 5"
    alt-shift-6 = "move --to-workspace 6"
    alt-shift-7 = "move --to-workspace 7"
    alt-shift-8 = "move --to-workspace 8"
    alt-shift-9 = "move --to-workspace 9"
    alt-shift-0 = "move --to-workspace 10"
    alt-q = "close"
    alt-v = "layout floating tiling"
    alt-f = "fullscreen"
    alt-slash = "layout tiles horizontal vertical"
    alt-comma = "workspace-back-and-forth"
    alt-shift-enter = "exec-and-forget open -n /Applications/Ghostty.app"

    [mode.main.binding.alt-minus]
    resize = "smart -50"

    [mode.main.binding.alt-equal]
    resize = "smart +50"

    [start-at-login]
    true

    [on-workspace-change]
    "sketchybar" = "sketchybar --trigger aerospace_workspace_change"
  '';
}
