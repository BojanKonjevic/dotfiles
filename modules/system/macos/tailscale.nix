{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}: {
  services.tailscale.enable = true;

  system.activationScripts.tailscale-authenticate = lib.mkIf (!userConfig.bootstrapMode) {
    text = ''
      if [[ -f "${config.age.secrets.tailscale.path}" ]]; then
        if ! ${pkgs.tailscale}/bin/tailscale status &>/dev/null; then
          ${pkgs.tailscale}/bin/tailscale up \
            --auth-key="$(cat ${config.age.secrets.tailscale.path})" \
            --ssh
        fi
      fi
    '';
  };
}
