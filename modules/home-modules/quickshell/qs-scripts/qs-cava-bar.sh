{
  pkgs,
  userConfig,
  theme,
}: ''
  exec ${pkgs.cava}/bin/cava -p ${userConfig.homeDirectory}/.config/cava/cava-bar.conf
''
