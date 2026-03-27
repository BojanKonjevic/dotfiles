{...}: {
  flake.homeModules.vesktop = {...}: {
    programs.vesktop = {
      enable = true;
      settings = {
        discordBranch = "stable";
        minimizeToTray = false;
        arRPC = true;
        splashColor = "rgb(205, 214, 244)";
        splashBackground = "rgb(17, 17, 27)";
        tray = false;
      };
      vencord.settings = {
        autoUpdate = false;
        autoUpdateNotification = true;
        useQuickCss = true;
        themeLinks = [
          "https://catppuccin.github.io/discord/dist/catppuccin-mocha.theme.css"
        ];
        eagerPatches = false;
        enabledThemes = [];
        enableReactDevtools = false;
        frameless = false;
        transparent = false;
        winCtrlQ = false;
        disableMinSize = false;
        winNativeTitleBar = false;

        notifications = {
          timeout = 5000;
          position = "bottom-right";
          useNative = "not-focused";
          logLimit = 50;
        };

        cloud = {
          authenticated = false;
          url = "https://api.vencord.dev/";
          settingsSync = false;
        };

        uiElements = {
          chatBarButtons = {};
          messagePopoverButtons = {};
        };

        plugins = {
          # ── APIs (required by other plugins) ────────────────────────────
          ChatInputButtonAPI = {enabled = true;};
          CommandsAPI = {enabled = true;};
          MessageAccessoriesAPI = {enabled = true;};
          MessageEventsAPI = {enabled = true;};
          MessagePopoverAPI = {enabled = true;};
          UserSettingsAPI = {enabled = true;};
          BadgeAPI = {enabled = true;};

          # ── Core / always-on ────────────────────────────────────────────
          CrashHandler = {enabled = true;};
          NoTrack = {
            enabled = true;
            disableAnalytics = true;
          };
          Settings = {
            enabled = true;
            settingsLocation = "aboveNitro";
          };
          SupportHelper = {enabled = true;};

          # ── Active plugins ──────────────────────────────────────────────
          AlwaysAnimate = {enabled = true;};
          AlwaysTrust = {
            enabled = true;
            domain = true;
            file = true;
          };
          BiggerStreamPreview = {enabled = true;};
          ClearURLs = {enabled = true;};
          DisableDeepLinks = {enabled = true;};

          FakeNitro = {
            enabled = true;
            enableStickerBypass = true;
            enableStreamQualityBypass = true;
            enableEmojiBypass = true;
            transformEmojis = true;
            transformStickers = true;
            transformCompoundSentence = false;
          };

          ImageZoom = {
            enabled = true;
            size = 288.9286998202517;
            zoom = 12.632589654977004;
            saveZoomValues = true;
            nearestNeighbour = false;
            square = false;
            invertScroll = true;
            zoomSpeed = 0.6636908328340324;
          };

          PictureInPicture = {
            enabled = true;
            loop = true;
          };
          ReverseImageSearch = {enabled = true;};

          Translate = {
            enabled = true;
            autoTranslate = false;
            showChatBarButton = true;
            receivedInput = "auto";
            service = "google";
            receivedOutput = "en";
            sentInput = "auto";
            sentOutput = "en";
          };

          ValidUser = {enabled = true;};
          VolumeBooster = {
            enabled = true;
            multiplier = 2.5;
          };
          WebContextMenus = {enabled = true;};
          WebKeybinds = {enabled = true;};
          WebScreenShareFixes = {enabled = true;};
          YoutubeAdblock = {enabled = true;};
        };
      };
    };
  };
}
