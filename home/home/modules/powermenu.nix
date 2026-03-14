{pkgs, ...}: {
  home.packages = with pkgs; [
    (writeShellScriptBin "power-menu" ''
      choice=$(printf '󰌾 Lock\n󰜉 Reboot\n󰐥 Power Off' \
        | rofi -dmenu \
            -theme ~/.config/rofi/power.rasi \
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
        base:      #1e1e2e;
        mantle:    #181825;
        surface0:  #313244;
        surface1:  #45475a;
        overlay0:  #6c7086;
        text:      #cdd6f4;

        font:             "JetBrainsMono Nerd Font 13";
        background-color: transparent;
        text-color:       @text;
    }

    window {
        width:            280px;
        background-color: @mantle;
        border:           2px;
        border-color:     #f38ba8;
        border-radius:    14px;
        padding:          0;
    }

    mainbox {
        padding:          12px;
        background-color: transparent;
        children:         [ inputbar, listview ];
        spacing:          10px;
    }

    inputbar {
        background-color: @surface0;
        border-radius:    10px;
        border:           1px;
        border-color:     @surface1;
        padding:          8px 14px;
        spacing:          8px;
        children:         [ prompt ];
    }

    prompt {
        text-color: #f38ba8;
        font:       "JetBrainsMono Nerd Font Bold 13";
    }

    listview {
        background-color: transparent;
        scrollbar:        false;
        lines:            3;
        columns:          1;
        spacing:          4px;
        fixed-height:     true;
    }

    element {
        orientation:      horizontal;
        padding:          10px 14px;
        border-radius:    9px;
        background-color: transparent;
        spacing:          12px;
    }

    element-text {
        vertical-align: 0.5;
        color:          @text;
    }

    element selected {
        background-color: #f38ba826;
        border:           1px;
        border-color:     #f38ba870;
    }
  '';
}
