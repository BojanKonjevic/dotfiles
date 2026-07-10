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
            "net.daringfireball.markdown"
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
  '';
}
