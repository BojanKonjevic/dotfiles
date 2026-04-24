{pkgs, ...}: let
  hexToRgb = hex: let
    r = builtins.fromJSON "0x${builtins.substring 1 2 hex}";
    g = builtins.fromJSON "0x${builtins.substring 3 2 hex}";
    b = builtins.fromJSON "0x${builtins.substring 5 2 hex}";
  in "${toString r}, ${toString g}, ${toString b}";

  scale = 1.0;
  s = v: builtins.floor (v * scale + 0.5);

  palette = rec {
    inherit scale;
    rounding = s 10;
    roundingPower = 2;
    gapsIn = s 3;
    gapsOut = s 5;
    borderSize =
      if scale < 0.75
      then 1
      else 2;
    radiusPanel = s 12;
    radiusPopup = s 14;
    radiusTile = s 10;
    radiusRow = s 8;
    radiusSmall = s 6;
    opacityPanel = 0.97;
    opacityBar = 0.60;
    opacityOverlay = 0.45;
    opacityBorder = 0.45;
    opacitySeparator = 0.30;
    barWidth = s 48;
    panelDateTime = s 340;
    panelMediaAudio = s 320;
    panelNotif = s 380;
    panelPower = s 200;
    popupLauncher = s 580;
    popupLauncherH = s 520;
    popupClipText = s 640;
    popupClipTextH = s 480;
    popupClipImg = s 820;
    popupClipImgH = s 600;
    popupWallpaper = s 820;
    popupWallpaperH = s 620;
    fontSizeXs = s 10;
    fontSizeSm = s 11;
    fontSizeMd = s 13;
    fontSizeLg = s 18;
    fontSizeXl = s 20;
    fontSize2Xl = s 28;
    fontSize3Xl = s 48;
    iconSizeSm = s 14;
    iconSizeMd = s 17;
    iconSizeLg = s 20;
    iconSizeXl = s 28;
    spacingXs = s 3;
    spacingSm = s 6;
    spacingMd = s 12;
    spacingLg = s 16;
    spacingXl = s 24;
    workspaceBtnH = s 22;
    mediaArtSize = s 64;
    sliderThumb = s 12;
    sliderTrackH = s 3;
    progressH = s 3;
    notifPopupW = s 364;
    notifPopupMargin = s 56;
    powerBtnH = s 40;
    cavaBars = s 20;
    base = "#1e1e2e";
    mantle = "#181825";
    crust = "#11111b";
    crustRgb = hexToRgb crust;
    surface0 = "#313244";
    surface0Rgb = hexToRgb surface0;
    surface1 = "#45475a";
    surface1Rgb = hexToRgb surface1;
    surface2 = "#585b70";
    overlay0 = "#6c7086";
    overlay1 = "#7f849c";
    overlay2 = "#9399b2";
    subtext0 = "#a6adc8";
    subtext1 = "#bac2de";
    text = "#cdd6f4";
    rosewater = "#f5e0dc";
    flamingo = "#f2cdcd";
    pink = "#f5c2e7";
    mauve = "#cba6f7";
    mauveRgb = hexToRgb mauve;
    red = "#f38ba8";
    redRgb = hexToRgb red;
    maroon = "#eba0ac";
    peach = "#fab387";
    yellow = "#f9e2af";
    green = "#a6e3a1";
    greenRgb = hexToRgb green;
    teal = "#94e2d5";
    sky = "#89dceb";
    sapphire = "#74c7ec";
    sapphireRgb = hexToRgb sapphire;
    blue = "#89b4fa";
    lavender = "#b4befe";
    lavenderRgb = hexToRgb lavender;
    cursorTheme = "catppuccin-mocha-mauve-cursors";
    cursorPackage = pkgs.catppuccin-cursors.mochaMauve;
    cursorSize = toString (s 20);
    fontName = "JetBrainsMono Nerd Font";
    fontPackage = pkgs.nerd-fonts.jetbrains-mono;
  };

  catppuccinGtk = pkgs.catppuccin-gtk.override {
    accents = ["mauve"];
    variant = "mocha";
  };
  themeName = "catppuccin-mocha-mauve-standard";
  themeDir = "${catppuccinGtk}/share/themes/${themeName}";
in {
  _module.args.theme = palette;
  home.packages = [
    palette.cursorPackage
    palette.fontPackage
  ];
  catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
  };
  gtk = {
    enable = true;
    theme = {
      name = themeName;
      package = catppuccinGtk;
    };
    cursorTheme = {
      name = palette.cursorTheme;
      package = palette.cursorPackage;
      size = s 20;
    };
    gtk3 = {
      extraConfig.gtk-application-prefer-dark-theme = 1;
      extraCss = builtins.readFile "${themeDir}/gtk-3.0/gtk.css";
    };
    gtk4 = {
      extraConfig.gtk-application-prefer-dark-theme = 1;
      extraCss = builtins.readFile "${themeDir}/gtk-4.0/gtk.css";
      theme = null;
    };
  };
  home.file.".config/gtk-4.0/assets" = {
    source = "${themeDir}/gtk-4.0/assets";
    recursive = true;
  };
  fonts = {
    fontconfig.enable = true;
    fontconfig.defaultFonts.monospace = [palette.fontName];
  };
}
