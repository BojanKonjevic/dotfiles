{...}: {
  services.swaync = {
    enable = true;

    settings = {
      widgets = [
        "title"
        "dnd"
        "volume"
        "mpris"
        "notifications"
      ];
    };
  };
}
