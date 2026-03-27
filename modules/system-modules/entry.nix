{...}: {
  flake.nixosModules.entry = {userConfig, ...}: {
    services.getty.autologinUser = userConfig.username;
    environment.loginShellInit = ''
      if [ "$(tty)" = "/dev/tty1" ]; then
        exec start-hyprland
      fi
    '';
  };
}
