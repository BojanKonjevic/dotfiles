{
  config,
  pkgs,
  lib,
  ...
}: {
  home.packages = [pkgs.duti];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
    TERMINAL = "kitty";
    XDG_TERMINAL = "kitty";
  };

  xdg.enable = true;

  home.activation.setDefaultApps = lib.hm.dag.entryAfter ["writeBoundary"] ''
    duti_bin="${pkgs.duti}/bin/duti"
    $VERBOSE_SET +x
    $duti_bin -s app.zen-browser.zen public.html 2>/dev/null || true
    $duti_bin -s app.zen-browser.zen public.url  2>/dev/null || true
    $duti_bin -s app.zen-browser.zen http        2>/dev/null || true
    $duti_bin -s app.zen-browser.zen https       2>/dev/null || true
    $VERBOSE_SET -x
  '';
}
