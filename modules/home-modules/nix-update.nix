{...}: {
  flake.homeModules.nix-update = {
    pkgs,
    userConfig,
    ...
  }: {
    home.packages = [
      (pkgs.writeShellScriptBin "nu" ''
        FLAKE="${userConfig.dotfilesDir}"
        CACHIX_CACHE="bojan-dotfiles"
        ${builtins.readFile ../lib/nu.sh}
      '')
    ];
  };
}
