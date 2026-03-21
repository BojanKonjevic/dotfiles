{
  pkgs,
  theme,
  ...
}: {
  home.packages = with pkgs; [
    (writeShellScriptBin "power-menu" ''
      choice=$(printf '󰌾 Lock\n󰜉 Reboot\n󰐥 Power Off' \
        | rofi -dmenu \
            -theme $HOME/.config/rofi/power.rasi \
            -p "Power" \
            -i \
            -no-custom)

      case "$choice" in
        *Lock*)      hyprlock ;;
        *Reboot*)     systemctl reboot ;;
        *Power\ Off*) systemctl poweroff ;;
      esac
    '')
  ];
  xdg.configFile."rofi/power.rasi".text = ''
    * {
        font:             "JetBrainsMono Nerd Font 13";
        background-color: transparent;
        text-color:       ${theme.text};
    }
    window {
        width:            300px;
        background-color: rgba(${theme.crustRgb}, 0.93);
        border:       1px;
        border-color: rgba(${theme.surface1Rgb}, 0.45);
        border-radius:    14px;
        padding:          0;
        children:         [ mainbox ];
    }
    mainbox {
        padding:          14px 14px 14px 14px;
        background-color: transparent;
        children:         [ inputbar, listview ];
        spacing:          14px;
    }
    inputbar {
        background-color: transparent;
        border-color:     rgba(${theme.redRgb}, 0.45);
        border:           0 0 2px 0;
        border-radius:    0;
        padding:          0 0 10px 0;
        spacing:          0;
        children:         [ prompt ];
    }
    prompt {
        text-color:     ${theme.red};
        font:           "JetBrainsMono Nerd Font Light 18";
        vertical-align: 0.5;
    }
    listview {
        background-color: transparent;
        scrollbar:        false;
        lines:            3;
        columns:          1;
        spacing:          3px;
        fixed-height:     true;
    }
    element {
        orientation:      horizontal;
        padding:          10px 14px;
        border-radius:    8px;
        background-color: transparent;
        border:       1px;
        border-color: transparent;
        spacing:          12px;
    }
    element-text {
        vertical-align: 0.5;
        text-color:     ${theme.subtext0};
        font:           "JetBrainsMono Nerd Font 13";
    }
    element selected {
        background-color: rgba(${theme.redRgb}, 0.18);
        border:       1px;
        border-color: rgba(${theme.redRgb}, 0.55);
        border-radius:    8px;
    }
    element selected element-text {
        text-color: ${theme.red};
        font:       "JetBrainsMono Nerd Font 13";
    }
  '';
}
