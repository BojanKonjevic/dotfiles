{
  pkgs,
  lib,
  theme,
  ...
}: let
  src = pkgs.fetchzip {
    url = "https://github.com/catppuccin/qbittorrent/archive/refs/tags/v2.0.1.zip";
    hash = "sha256-JuD/4a+r+PLNqogVQl2yPhn5Q7R49Fm77QhXS9MCj+U=";
    stripRoot = false;
  };

  configJson = pkgs.writeText "config.json" (builtins.toJSON {
    colors = {
      "Palette.Window" = theme.base;
      "Palette.WindowText" = theme.text;
      "Palette.Base" = theme.crust;
      "Palette.AlternateBase" = theme.mantle;
      "Palette.Text" = theme.text;
      "Palette.ToolTipBase" = theme.surface0;
      "Palette.ToolTipText" = theme.text;
      "Palette.BrightText" = theme.mauve;
      "Palette.Highlight" = theme.blue;
      "Palette.HighlightedText" = theme.crust;
      "Palette.Button" = theme.surface0;
      "Palette.ButtonText" = theme.text;
      "Palette.Link" = theme.blue;
      "Palette.LinkVisited" = theme.lavender;
      "Palette.Light" = theme.surface2;
      "Palette.Midlight" = theme.surface1;
      "Palette.Mid" = theme.base;
      "Palette.Dark" = theme.mantle;
      "Palette.Shadow" = theme.crust;
      "Palette.PlaceholderText" = theme.overlay2;
      "Palette.WindowTextDisabled" = theme.overlay1;
      "Palette.TextDisabled" = theme.overlay1;
      "Palette.ToolTipTextDisabled" = theme.overlay1;
      "Palette.BrightTextDisabled" = theme.overlay1;
      "Palette.HighlightedTextDisabled" = theme.overlay1;
      "Palette.ButtonTextDisabled" = theme.overlay1;

      "RSS.ReadArticle" = theme.overlay2;
      "RSS.UnreadArticle" = theme.blue;

      "Log.TimeStamp" = theme.subtext1;
      "Log.Normal" = theme.text;
      "Log.Info" = theme.blue;
      "Log.Warning" = theme.peach;
      "Log.Critical" = theme.red;
      "Log.BannedPeer" = theme.red;

      "TransferList.Downloading" = theme.green;
      "TransferList.StalledDownloading" = theme.overlay1;
      "TransferList.DownloadingMetadata" = theme.green;
      "TransferList.ForcedDownloadingMetadata" = theme.sky;
      "TransferList.ForcedDownloading" = theme.green;
      "TransferList.Uploading" = theme.blue;
      "TransferList.StalledUploading" = theme.overlay1;
      "TransferList.ForcedUploading" = theme.blue;
      "TransferList.QueuedDownloading" = theme.teal;
      "TransferList.QueuedUploading" = theme.teal;
      "TransferList.CheckingDownloading" = theme.teal;
      "TransferList.CheckingUploading" = theme.teal;
      "TransferList.CheckingResumeData" = theme.teal;
      "TransferList.PausedDownloading" = theme.peach;
      "TransferList.PausedUploading" = theme.peach;
      "TransferList.Moving" = theme.teal;
      "TransferList.MissingFiles" = theme.red;
      "TransferList.Error" = theme.red;
    };
  });

  qbtheme = pkgs.runCommand "catppuccin-mocha-mauve.qbtheme" {} ''
    base="${src}/qbittorrent-2.0.1"

    mkdir -p work/src/catppuccin-mocha work/src/icons/dark
    cp -r "$base/src/icons/dark/."                    work/src/icons/dark/
    cp    "$base/src/catppuccin-mocha/stylesheet.qss" work/src/catppuccin-mocha/
    cp    "${configJson}"                             work/src/catppuccin-mocha/config.json
    cp    "$base/src/catppuccin-mocha/resources.qrc"  work/src/catppuccin-mocha/

    cd work/src/catppuccin-mocha
    ${pkgs.qt6.qtbase}/libexec/rcc --binary resources.qrc -o "$out"
  '';

  themePath = "${qbtheme}";
in {
  home.packages = [pkgs.qbittorrent];

  home.file.".local/share/qBittorrent/themes/catppuccin-mocha-mauve.qbtheme".source =
    themePath;

  home.activation.qbittorrentTheme = lib.hm.dag.entryAfter ["writeBoundary"] ''
    _conf="$HOME/.config/qBittorrent/qBittorrent.conf"
    _theme="${themePath}"
    _awk="${pkgs.gawk}/bin/awk"
    _sed="${pkgs.gnused}/bin/sed"

    mkdir -p "$(dirname "$_conf")"
    [ -f "$_conf" ] || touch "$_conf"

    grep -qF '[Preferences]' "$_conf" || echo '[Preferences]' >> "$_conf"

    # Clean up any keys from previous broken runs
    "$_sed" -i '/^General\\CustomUITheme=/d'     "$_conf"
    "$_sed" -i '/^GeneralCustomUITheme=/d'        "$_conf"
    "$_sed" -i '/^General\\CustomUIThemePath=/d'  "$_conf"

    upsert() {
      local key="''$1" val="''$2" file="''$3"
      if grep -qF "''${key}=" "''$file"; then
        key="''$key" val="''$val" "$_awk" '
          BEGIN { k = ENVIRON["key"]; v = ENVIRON["val"] }
          index($0, k"=") == 1 { print k"="v; next }
          { print }
        ' "''$file" > "''${file}.tmp" && mv "''${file}.tmp" "''$file"
      else
        key="''$key" val="''$val" "$_awk" '
          BEGIN { k = ENVIRON["key"]; v = ENVIRON["val"] }
          /^\[Preferences\]/ { print; print k"="v; next }
          { print }
        ' "''$file" > "''${file}.tmp" && mv "''${file}.tmp" "''$file"
      fi
    }

    upsert 'General\CustomUIThemePath' "$_theme" "$_conf"
    upsert 'General\UseCustomUITheme'  'true'    "$_conf"
  '';
}
