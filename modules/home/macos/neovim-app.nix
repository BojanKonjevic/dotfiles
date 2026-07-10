{
  pkgs,
  lib,
  ...
}: let
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

        /usr/bin/plutil -insert CFBundleDocumentTypes -json '[
        {
          "CFBundleTypeName": "Text File",
          "CFBundleTypeRole": "Editor",
          "LSHandlerRank": "Default",
          "LSItemContentTypes": [
            "public.plain-text",
            "public.source-code",
            "public.script",
            "public.shell-script",
            "public.text",
            "public.json",
            "public.yaml",
            "public.xml",
            "net.daringfireball.markdown",
            "public.c-source",
            "public.objective-c-source",
            "public.c-plus-plus-source",
            "public.assembly",
            "public.makefile",
            "public.ruby-script",
            "public.python-script",
            "public.perl-script",
            "public.javascript"
          ],
          "CFBundleTypeExtensions": [
            "c",
            "m",
            "mm",
            "h",
            "nix",
            "lock",
            "rs",
            "go",
            "rb",
            "py",
            "js",
            "ts",
            "jsx",
            "tsx",
            "toml",
            "plist",
            "proto",
            "css",
            "scss",
            "less",

            "svelte",
            "vue",
            "tex",
            "lua",
            "zig",
            "kt",
            "kts",
            "swift",
            "scala",
            "clj",
            "cljs",
            "cljc",
            "edn",
            "el",
            "ex",

            "erl",
            "hs",
            "ml",
            "mli",
            "php",
            "pl",
            "r",
            "sql",
            "cfg",
            "conf",
            "ini",
            "env",
            "gitignore",
            "gitattributes",
            "editorconfig",
            "sh",
            "bash",
            "zsh",
            "fish"
          ]
        }
        ]' "$out/Contents/Info.plist"

        icon_png="${pkgs.neovim}/share/icons/hicolor/128x128/apps/nvim.png"
        if [ -f "$icon_png" ]; then
          iconset="$out/Contents/Resources/Neovim.iconset"
          mkdir -p "$iconset"
          cp "$icon_png" "$iconset/icon_128x128.png"
          /usr/bin/iconutil -c icns "$iconset" -o "$out/Contents/Resources/Neovim.icns" 2>/dev/null || true
          /usr/bin/plutil -insert CFBundleIconFile -string "Neovim" "$out/Contents/Info.plist"
          rm -rf "$iconset"
        fi
  '';
in {
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

    duti_bin="${pkgs.duti}/bin/duti"
    $duti_bin -s nvim public.plain-text 2>/dev/null || true
    $duti_bin -s nvim public.source-code 2>/dev/null || true
    $duti_bin -s nvim public.script 2>/dev/null || true
    $duti_bin -s nvim public.shell-script 2>/dev/null || true
    $duti_bin -s nvim public.text 2>/dev/null || true
    $duti_bin -s nvim public.json 2>/dev/null || true
    $duti_bin -s nvim public.yaml 2>/dev/null || true
    $duti_bin -s nvim public.xml 2>/dev/null || true
    $duti_bin -s nvim net.daringfireball.markdown 2>/dev/null || true
    $duti_bin -s nvim .c all 2>/dev/null || true
    $duti_bin -s nvim .m all 2>/dev/null || true
    $duti_bin -s nvim .mm all 2>/dev/null || true
    $duti_bin -s nvim .h all 2>/dev/null || true
    $duti_bin -s nvim .nix all 2>/dev/null || true
    $duti_bin -s nvim .lock all 2>/dev/null || true
    $duti_bin -s nvim .rs all 2>/dev/null || true
    $duti_bin -s nvim .go all 2>/dev/null || true
    $duti_bin -s nvim .rb all 2>/dev/null || true
    $duti_bin -s nvim .py all 2>/dev/null || true
    $duti_bin -s nvim .js all 2>/dev/null || true
    $duti_bin -s nvim .ts all 2>/dev/null || true
    $duti_bin -s nvim .jsx all 2>/dev/null || true
    $duti_bin -s nvim .tsx all 2>/dev/null || true
    $duti_bin -s nvim .toml all 2>/dev/null || true
    $duti_bin -s nvim .plist all 2>/dev/null || true
    $duti_bin -s nvim .proto all 2>/dev/null || true
    $duti_bin -s nvim .css all 2>/dev/null || true
    $duti_bin -s nvim .scss all 2>/dev/null || true
    $duti_bin -s nvim .less all 2>/dev/null || true
    $duti_bin -s nvim .svelte all 2>/dev/null || true
    $duti_bin -s nvim .vue all 2>/dev/null || true
    $duti_bin -s nvim .tex all 2>/dev/null || true
    $duti_bin -s nvim .lua all 2>/dev/null || true
    $duti_bin -s nvim .zig all 2>/dev/null || true
    $duti_bin -s nvim .kt all 2>/dev/null || true
    $duti_bin -s nvim .kts all 2>/dev/null || true
    $duti_bin -s nvim .swift all 2>/dev/null || true
    $duti_bin -s nvim .scala all 2>/dev/null || true
    $duti_bin -s nvim .clj all 2>/dev/null || true
    $duti_bin -s nvim .cljs all 2>/dev/null || true
    $duti_bin -s nvim .cljc all 2>/dev/null || true
    $duti_bin -s nvim .edn all 2>/dev/null || true
    $duti_bin -s nvim .el all 2>/dev/null || true
    $duti_bin -s nvim .ex all 2>/dev/null || true
    $duti_bin -s nvim .erl all 2>/dev/null || true
    $duti_bin -s nvim .hs all 2>/dev/null || true
    $duti_bin -s nvim .ml all 2>/dev/null || true
    $duti_bin -s nvim .mli all 2>/dev/null || true
    $duti_bin -s nvim .php all 2>/dev/null || true
    $duti_bin -s nvim .pl all 2>/dev/null || true
    $duti_bin -s nvim .r all 2>/dev/null || true
    $duti_bin -s nvim .sql all 2>/dev/null || true
    $duti_bin -s nvim .cfg all 2>/dev/null || true
    $duti_bin -s nvim .conf all 2>/dev/null || true
    $duti_bin -s nvim .ini all 2>/dev/null || true
    $duti_bin -s nvim .env all 2>/dev/null || true
    $duti_bin -s nvim .gitignore all 2>/dev/null || true
    $duti_bin -s nvim .gitattributes all 2>/dev/null || true
    $duti_bin -s nvim .editorconfig all 2>/dev/null || true
  '';
}
