{...}: {
  flake.nixosModules.first-login = {
    pkgs,
    userConfig,
    ...
  }: {
    systemd.user.services.hm-first-login = {
      description = "Home Manager first login bootstrap";
      wantedBy = ["default.target"];
      after = ["network-online.target"];
      wants = ["network-online.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "hm-first-login" ''
          SENTINEL="$HOME/.config/.hm-bootstrapped"
          [[ -f "$SENTINEL" ]] && exit 0
          ${pkgs.home-manager}/bin/home-manager switch \
            --flake "${userConfig.dotfilesDir}#${userConfig.username}" \
            --option download-buffer-size 134217728
          mkdir -p "$(dirname "$SENTINEL")"
          touch "$SENTINEL"
        '';
      };
    };
  };
}
