{
  pkgs,
  lib,
  ...
}: let
  # ── file associations (single source of truth) ──────────────
  # UTIs with their typical extensions (if non-obvious)
  utiAssoc = {
    "public.plain-text" = [];
    "public.source-code" = [];
    "public.script" = [];
    "public.shell-script" = ["sh" "bash" "zsh"];
    "public.text" = [];
    "public.json" = [];
    "public.yaml" = [];
    "public.xml" = [];
    "net.daringfireball.markdown" = [];
    "public.c-source" = ["c" "h"];
    "public.objective-c-source" = ["m"];
    "public.c-plus-plus-source" = ["mm"];
    "public.assembly" = [];
    "public.makefile" = [];
    "public.ruby-script" = ["rb"];
    "public.python-script" = ["py"];
    "public.perl-script" = ["pl"];
    "public.javascript" = ["js"];
  };

  # Extensions without a system-defined UTI — macOS doesn't know them,
  # so duti can't bind them. We export custom UTIs conforming to
  # public.source-code so that `duti -s nvim public.source-code` covers them.
  customUtis = [
    {
      id = "org.nix-community.nix";
      exts = ["nix" "lock"];
    }
    {
      id = "org.nix-community.rust";
      exts = ["rs"];
    }
    {
      id = "org.nix-community.go";
      exts = ["go"];
    }
    {
      id = "org.nix-community.javascript";
      exts = ["jsx"];
    }
    {
      id = "org.nix-community.tsx";
      exts = ["tsx"];
    }
    {
      id = "org.nix-community.toml";
      exts = ["toml"];
    }
    {
      id = "org.nix-community.plist";
      exts = ["plist"];
    }
    {
      id = "org.nix-community.protobuf";
      exts = ["proto"];
    }
    {
      id = "org.nix-community.scss";
      exts = ["scss" "less"];
    }
    {
      id = "org.nix-community.svelte";
      exts = ["svelte"];
    }
    {
      id = "org.nix-community.vue";
      exts = ["vue"];
    }
    {
      id = "org.nix-community.tex";
      exts = ["tex"];
    }
    {
      id = "org.nix-community.lua";
      exts = ["lua"];
    }
    {
      id = "org.nix-community.zig";
      exts = ["zig"];
    }
    {
      id = "org.nix-community.kotlin";
      exts = ["kt" "kts"];
    }
    {
      id = "org.nix-community.scala";
      exts = ["scala"];
    }
    {
      id = "org.nix-community.clojure";
      exts = ["clj" "cljs" "cljc" "edn"];
    }
    {
      id = "org.nix-community.emacs";
      exts = ["el"];
    }
    {
      id = "org.nix-community.elixir";
      exts = ["ex"];
    }
    {
      id = "org.nix-community.erlang";
      exts = ["erl"];
    }
    {
      id = "org.nix-community.haskell";
      exts = ["hs"];
    }
    {
      id = "org.nix-community.ocaml";
      exts = ["ml" "mli"];
    }
    {
      id = "org.nix-community.config";
      exts = ["cfg" "conf" "ini" "env" "gitignore" "gitattributes" "editorconfig"];
    }
  ];

  # All extensions we want Neovim.app to appear for in the "Open With" menu
  allExtensions = lib.lists.unique (
    (lib.concatLists (lib.attrValues utiAssoc))
    ++ (lib.concatLists (map (u: u.exts) customUtis))
    ++ ["ts" "css" "php" "r" "sql" "swift" "fish"]
  );

  allUtis = builtins.attrNames utiAssoc;

  docTypesJson = builtins.toJSON [
    {
      CFBundleTypeName = "Text File";
      CFBundleTypeRole = "Editor";
      LSHandlerRank = "Default";
      LSItemContentTypes = allUtis;
      CFBundleTypeExtensions = allExtensions;
    }
  ];

  customUtisJson = builtins.toJSON (map (u: {
      UTTypeIdentifier = u.id;
      UTTypeTagSpecification = {"public.filename-extension" = u.exts;};
      UTTypeConformsTo = ["public.source-code"];
    })
    customUtis);

  dutiBase = "${pkgs.duti}/bin/duti";

  dutiCommands = lib.concatStringsSep "\n" (
    (map (uti: ''$duti_bin -s nvim "${uti}" 2>/dev/null || true'') allUtis)
    ++ (map (ext: ''$duti_bin -s nvim "${ext}" all 2>/dev/null || true'') (map (e: ".${e}") allExtensions))
  );

  # ── ObjC launcher — opens nvim through Ghostty ─────────────
  mainSrc = pkgs.writeText "main.m" ''
    #import <AppKit/AppKit.h>
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    @interface AppDelegate : NSObject <NSApplicationDelegate>
    @end
    @implementation AppDelegate
    - (void)applicationDidFinishLaunching:(NSNotification *)notification {
      if ([[NSProcessInfo processInfo] arguments].count <= 1)
        [self launchWithFile:nil];
      [NSApp terminate:nil];
    }
    - (void)application:(NSApplication *)sender openFiles:(NSArray<NSString *> *)filenames {
      for (NSString *path in filenames)
        [self launchWithFile:path];
      [NSApp terminate:nil];
    }
    - (void)launchWithFile:(NSString *)file {
      NSTask *task = [[NSTask alloc] init];
      task.launchPath = @"/usr/bin/open";
      NSString *shellCmd;
      if (file) {
        shellCmd = [NSString stringWithFormat:@"exec nvim \"%@\"", file];
      } else {
        shellCmd = @"exec nvim";
      }
      task.arguments = @[@"-n", @"-a", @"Ghostty", @"--args",
        @"-e", @"/bin/zsh", @"-c", shellCmd];
      [task launch];
      [task waitUntilExit];
    }
    @end
    #pragma clang diagnostic pop
    int main() {
      @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setDelegate:[[AppDelegate alloc] init]];
        [app run];
      }
      return 0;
    }
  '';

  neovimApp = pkgs.runCommandLocal "Neovim.app" {} ''
    mkdir -p "$out/Contents/MacOS" "$out/Contents/Resources"

    cp "${mainSrc}" "$TMPDIR/main.m"
    /usr/bin/clang -framework Foundation -framework AppKit \
      -o "$out/Contents/MacOS/Neovim" "$TMPDIR/main.m" 2>&1

    cat > "$out/Contents/Info.plist" << 'EOF'
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict/>
    </plist>
    EOF

    /usr/bin/plutil -insert CFBundleExecutable -string "Neovim" "$out/Contents/Info.plist"
    /usr/bin/plutil -insert CFBundleIdentifier -string "nvim" "$out/Contents/Info.plist"
    /usr/bin/plutil -insert CFBundleName -string "Neovim" "$out/Contents/Info.plist"
    /usr/bin/plutil -insert CFBundlePackageType -string "APPL" "$out/Contents/Info.plist"
    /usr/bin/plutil -insert CFBundleVersion -string "1" "$out/Contents/Info.plist"
    /usr/bin/plutil -insert CFBundleInfoDictionaryVersion -string "6.0" "$out/Contents/Info.plist"
    /usr/bin/plutil -insert LSMinimumSystemVersion -string "14.0" "$out/Contents/Info.plist"

    /usr/bin/plutil -insert CFBundleDocumentTypes -json '${docTypesJson}' "$out/Contents/Info.plist"
    /usr/bin/plutil -insert UTExportedTypeDeclarations -json '${customUtisJson}' "$out/Contents/Info.plist"

    icon_png="${pkgs.neovim}/share/icons/hicolor/128x128/apps/nvim.png"
    if [ -f "$icon_png" ]; then
      iconset="$out/Contents/Resources/Neovim.iconset"
      mkdir -p "$iconset"
      cp "$icon_png" "$iconset/icon_128x128.png"
      /usr/bin/iconutil -c icns "$iconset" \
        -o "$out/Contents/Resources/Neovim.icns" 2>/dev/null || true
      /usr/bin/plutil -insert CFBundleIconFile -string "Neovim" "$out/Contents/Info.plist"
      rm -rf "$iconset"
    fi
  '';
in {
  home.packages = [pkgs.duti];

  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    SUDO_EDITOR = "nvim";
    TERMINAL = "ghostty";
    XDG_TERMINAL = "ghostty";
  };

  xdg.enable = true;

  home.activation.setNeovimApp = lib.hm.dag.entryAfter ["writeBoundary"] ''
    APP_DIR="$HOME/Applications/Neovim.app"
    LSREGISTER="/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister"

    if [ -d "$APP_DIR" ]; then
      "$LSREGISTER" -u "$APP_DIR" 2>/dev/null || true
      rm -rf "$APP_DIR"
    fi
    mkdir -p "$HOME/Applications"
    cp -r "${neovimApp}" "$APP_DIR"
    chmod -R u+w "$APP_DIR"
    xattr -dr com.apple.quarantine "$APP_DIR" 2>/dev/null || true
    /usr/bin/codesign --force --sign - "$APP_DIR" 2>/dev/null || true

    "$LSREGISTER" -f "$APP_DIR" 2>/dev/null || true

    duti_bin="${dutiBase}"
    ${dutiCommands}
  '';

  home.activation.setBrowserDefaults = lib.hm.dag.entryAfter ["writeBoundary"] ''
    duti_bin="${dutiBase}"
    $duti_bin -s app.zen-browser.zen public.html 2>/dev/null || true
    $duti_bin -s app.zen-browser.zen public.url  2>/dev/null || true
    $duti_bin -s app.zen-browser.zen http        2>/dev/null || true
    $duti_bin -s app.zen-browser.zen https       2>/dev/null || true
  '';
}
