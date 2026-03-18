{lib, ...}: {
  services.swaync = {
    enable = true;

    settings = {
      positionX = "right";
      positionY = "top";
      layer = "overlay";
      control-center-layer = "top";
      control-center-margin-top = 0;
      control-center-margin-bottom = 0;
      control-center-margin-right = 0;
      control-center-margin-left = 0;
      control-center-width = 360;
      notification-window-width = 360;

      timeout = 5;
      timeout-low = 2;
      timeout-critical = 0;
      transition-time = 200;

      keyboard-shortcuts = true;
      image-visibility = "when-available";
      hide-on-clear = false;
      hide-on-action = true;
      script-fail-notify = true;

      widgets = [
        "title"
        "dnd"
        "volume"
        "mpris"
        "notifications"
      ];

      widget-config = {
        title = {
          text = "Notifications";
          clear-all-button = true;
          button-text = "Clear All";
        };
        dnd = {
          text = "Do Not Disturb";
        };
        volume = {
          label = "󰕾";
          expand-button-label = "󰒓";
          collapse-button-label = "󰒓";
          show-per-app = true;
          show-per-app-icon = true;
          show-per-app-label = false;
        };
        mpris = {
          image-size = 52;
          image-radius = 6;
        };
      };
    };
  };
}
