{
  config,
  theme,
  ...
}: let
  zenProfile = "${config.home.username}.default";
in {
  programs.zen-browser = {
    enable = true;
    policies = {
      SearchEngines = {
        Default = "Google EN";
        Add = [
          {
            Name = "Google EN";
            URLTemplate = "https://www.google.com/search?q={searchTerms}&hl=en&gl=us";
            Method = "GET";
            IconURL = "https://www.google.com/favicon.ico";
            SuggestURLTemplate = "https://www.google.com/complete/search?client=firefox&q={searchTerms}";
          }
        ];
      };
      DisableAppUpdate = true;
      DisableTelemetry = true;
      ExtensionSettings = {
        "uBlock0@raymondhill.net" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          installation_mode = "force_installed";
        };
        "sponsorBlocker@ajay.app" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/sponsorblock/latest.xpi";
          installation_mode = "force_installed";
        };
        "{762f9885-5a13-4abd-9c77-433dcd38b8fd}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/return-youtube-dislikes/latest.xpi";
          installation_mode = "force_installed";
        };
        "jid1-93WyvpgvxzGATw@jetpack" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/to-google-translate/latest.xpi";
          installation_mode = "force_installed";
        };
        "{7a7a4a92-a2a0-41d1-9fd7-1e92480d612d}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/styl-us/latest.xpi";
          installation_mode = "force_installed";
        };
        "{d7742d87-e61d-4b78-b8a1-b469842139fa}" = {
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/vimium-ff/latest.xpi";
          installation_mode = "force_installed";
        };
      };
    };
  };
  home.file.".zen/profiles.ini".text = ''
    [Profile0]
    Name=${config.home.username}
    IsRelative=1
    Path=${zenProfile}
    Default=1

    [General]
    StartWithLastProfile=1
    Version=2

    [Install15B76BAA26BA15E7]
    Default=${zenProfile}
    Locked=1
  '';

  home.file.".zen/${zenProfile}/user.js".text = ''
    user_pref("font.name.monospace.x-western", "JetBrainsMono Nerd Font");
    user_pref("font.name.sans-serif.x-western", "JetBrainsMono Nerd Font");
    user_pref("font.name.serif.x-western", "JetBrainsMono Nerd Font");
    user_pref("font.size.variable.x-western", 14);
    user_pref("layout.css.prefers-color-scheme.content-override", 0);
    user_pref("browser.display.document_color_use", 0);
    user_pref("layers.acceleration.force-enabled", true);
    user_pref("general.smoothScroll", true);
    user_pref("general.autoScroll", true);
    user_pref("network.dns.disablePrefetch", true);
    user_pref("network.prefetch-next", false);
    user_pref("network.http.speculative-parallel-limit", 0);
    user_pref("signon.rememberSignons", false);
    user_pref("privacy.globalprivacycontrol.was_ever_enabled", true);
    user_pref("privacy.clearOnShutdown_v2.formdata", true);
    user_pref("browser.tabs.allow_transparent_browser", true);
    user_pref("browser.link.open_newwindow.restriction", 0);
    user_pref("browser.shell.checkDefaultBrowser", false);
    user_pref("browser.warnOnQuitShortcut", false);
    user_pref("browser.aboutConfig.showWarning", false);
    user_pref("browser.search.separatePrivateDefault", false);
    user_pref("browser.newtabpage.activity-stream.showSearch", false);
    user_pref("browser.newtabpage.activity-stream.feeds.topsites", true);
    user_pref("accessibility.typeaheadfind.flashBar", 0);
    user_pref("devtools.responsive.reloadNotification.enabled", false);
    user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
    user_pref("extensions.autoDisableScopes", 0);
    user_pref("zen.tabs.vertical.right-side", true);
    user_pref("zen.tabs.show-newtab-vertical", false);
    user_pref("zen.view.compact.hide-tabbar", true);
    user_pref("zen.view.compact.hide-toolbar", true);
    user_pref("zen.view.compact.show-sidebar-and-toolbar-on-hover", true);
    user_pref("zen.view.compact.toolbar-flash-popup", false);
    user_pref("zen.view.compact.sidebar-keep-hover-duration", 150);
    user_pref("zen.view.show-newtab-button-top", false);
    user_pref("zen.workspaces.continue-where-left-off", true);
    user_pref("intl.locale.requested", "en-US");
    user_pref("browser.search.region", "US");
    user_pref("browser.search.detectCurrentRegion", false);
    user_pref("browser.search.geoSpecificDefaults", false);
    user_pref("browser.search.geoip.url", "");
    user_pref("geo.enabled", false);
    user_pref("geo.provider.network.url", "");
    user_pref("geo.provider.use_gpsd", false);
    user_pref("geo.provider.use_geoclue", false);
  '';

  home.file.".zen/${zenProfile}/chrome/userChrome.css".text = ''
    :root {
      --zen-primary-color: ${theme.mauve} !important;
      --zen-colors-primary: ${theme.surface0} !important;
      --zen-colors-secondary: ${theme.surface0} !important;
      --zen-colors-tertiary: ${theme.mantle} !important;
      --zen-themed-toolbar-bg: ${theme.mantle} !important;
      --zen-main-browser-background: ${theme.mantle} !important;
      --zen-view-background: ${theme.base} !important;
    }

    #zen-sidebar,
    #sidebar-box,
    #sidebar-splitter,
    #zen-sidepanel,
    #zen-workspaces-box,
    #zen-workspaces-button,
    #tabbrowser-tabs {
      background-color: ${theme.crust} !important;
      color: ${theme.text} !important;
      border-color: ${theme.surface0} !important;
    }

    #tabbrowser-tabs .tabbrowser-tab[selected="true"],
    #tabbrowser-tabs .tabbrowser-tab[visuallyselected="true"],
    #zen-workspaces-button[active],
    #zen-workspaces-button[selected] {
      background-color: ${theme.surface0} !important;
      color: ${theme.mauve} !important;
      border-inline-start-color: ${theme.mauve} !important;
    }

    #urlbar[open],
    .urlbarView,
    .urlbarView-results,
    .urlbarView-row,
    .urlbarView-url,
    #urlbar-background,
    #urlbar[breakout][open] > #urlbar-input-container {
      background-color: ${theme.base} !important;
      color: ${theme.text} !important;
    }

    #navigator-toolbox {
      width: 300px !important;
      max-width: 600px !important;
      --zen-sidebar-width: 300px !important;
      --actual-zen-sidebar-width: 300px !important;
    }

    .urlbarView-row[selected] {
      background-color: ${theme.surface0} !important;
    }

    #newtabGrid,
    #newtab-margin,
    .newtab-customize-overlay,
    .browserContainer,
    #newtab-page {
      background-color: ${theme.base} !important;
    }

    #PopupAutoCompleteRichResult,
    menupopup,
    menu,
    menuitem,
    .panel-arrowcontent {
      background-color: ${theme.base} !important;
      color: ${theme.text} !important;
      --arrowpanel-background: ${theme.base} !important;
    }

    toolbarbutton:hover,
    .toolbarbutton-1:hover,
    #zen-workspaces-button:hover {
      background-color: ${theme.surface0} !important;
    }
  '';

  home.file.".zen/${zenProfile}/chrome/userContent.css".text = ''
    @media (prefers-color-scheme: dark) {

      @-moz-document url-prefix("about:") {
        :root {
          --in-content-page-color: ${theme.text} !important;
          --color-accent-primary: ${theme.mauve} !important;
          --color-accent-primary-hover: rgb(217, 191, 249) !important;
          --color-accent-primary-active: rgb(223, 167, 247) !important;
          background-color: ${theme.base} !important;
          --in-content-page-background: ${theme.base} !important;
        }
      }

      @-moz-document url("about:newtab"), url("about:home") {
        :root {
          --newtab-background-color: ${theme.base} !important;
          --newtab-background-color-secondary: ${theme.surface0} !important;
          --newtab-element-hover-color: ${theme.surface0} !important;
          --newtab-text-primary-color: ${theme.text} !important;
          --newtab-wordmark-color: ${theme.text} !important;
          --newtab-primary-action-background: ${theme.mauve} !important;
        }
        .icon { color: ${theme.mauve} !important; }
        .card-outer:is(:hover, :focus, .active):not(.placeholder) .card-title {
          color: ${theme.mauve} !important;
        }
        .top-site-outer .search-topsite {
          background-color: ${theme.blue} !important;
        }
      }

      @-moz-document url-prefix("about:preferences") {
        :root {
          --zen-colors-tertiary: ${theme.mantle} !important;
          --in-content-text-color: ${theme.text} !important;
          --link-color: ${theme.mauve} !important;
          --link-color-hover: rgb(217, 191, 249) !important;
          --zen-colors-primary: ${theme.surface0} !important;
          --in-content-box-background: ${theme.surface0} !important;
          --zen-primary-color: ${theme.mauve} !important;
        }
        groupbox, moz-card { background: ${theme.base} !important; }
        button, groupbox menulist {
          background: ${theme.surface0} !important;
          color: ${theme.text} !important;
        }
        .main-content { background-color: ${theme.crust} !important; }
        .identity-color-blue      { --identity-tab-color: #8aadf4 !important; --identity-icon-color: #8aadf4 !important; }
        .identity-color-turquoise { --identity-tab-color: #8bd5ca !important; --identity-icon-color: #8bd5ca !important; }
        .identity-color-green     { --identity-tab-color: #a6da95 !important; --identity-icon-color: #a6da95 !important; }
        .identity-color-yellow    { --identity-tab-color: #eed49f !important; --identity-icon-color: #eed49f !important; }
        .identity-color-orange    { --identity-tab-color: #f5a97f !important; --identity-icon-color: #f5a97f !important; }
        .identity-color-red       { --identity-tab-color: #ed8796 !important; --identity-icon-color: #ed8796 !important; }
        .identity-color-pink      { --identity-tab-color: #f5bde6 !important; --identity-icon-color: #f5bde6 !important; }
        .identity-color-purple    { --identity-tab-color: #c6a0f6 !important; --identity-icon-color: #c6a0f6 !important; }
      }

      @-moz-document url-prefix("about:addons") {
        :root {
          --zen-dark-color-mix-base: ${theme.mantle} !important;
          --background-color-box: ${theme.base} !important;
        }
      }

      @-moz-document url-prefix("about:protections") {
        :root {
          --zen-primary-color: ${theme.base} !important;
          --social-color: ${theme.mauve} !important;
          --coockie-color: ${theme.sky} !important;
          --fingerprinter-color: ${theme.yellow} !important;
          --cryptominer-color: ${theme.lavender} !important;
          --tracker-color: ${theme.green} !important;
          --in-content-primary-button-background-hover: ${theme.surface2} !important;
          --in-content-primary-button-text-color-hover: ${theme.text} !important;
          --in-content-primary-button-background: ${theme.surface1} !important;
          --in-content-primary-button-text-color: ${theme.text} !important;
        }
        .card { background-color: ${theme.surface0} !important; }
      }
    }
  '';

  home.file.".zen/${zenProfile}/zen-keyboard-shortcuts.json".text = builtins.toJSON {
    shortcuts = [
      {
        id = "key_wrToggleCaptureSequenceCmd";
        key = "^";
        keycode = null;
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "wrToggleCaptureSequenceCmd";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_wrCaptureCmd";
        key = "#";
        keycode = null;
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "wrCaptureCmd";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_selectLastTab";
        key = "9";
        keycode = null;
        group = "windowAndTabManagement";
        l10nId = null;
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_selectTab8";
        key = "8";
        keycode = null;
        group = "windowAndTabManagement";
        l10nId = null;
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_selectTab7";
        key = "7";
        keycode = null;
        group = "windowAndTabManagement";
        l10nId = null;
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_selectTab6";
        key = "6";
        keycode = null;
        group = "windowAndTabManagement";
        l10nId = null;
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_selectTab5";
        key = "5";
        keycode = null;
        group = "windowAndTabManagement";
        l10nId = null;
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_selectTab4";
        key = "4";
        keycode = null;
        group = "windowAndTabManagement";
        l10nId = null;
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_selectTab3";
        key = "3";
        keycode = null;
        group = "windowAndTabManagement";
        l10nId = null;
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_selectTab2";
        key = "2";
        keycode = null;
        group = "windowAndTabManagement";
        l10nId = null;
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_selectTab1";
        key = "1";
        keycode = null;
        group = "windowAndTabManagement";
        l10nId = null;
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_undoCloseWindow";
        key = "";
        keycode = "";
        group = "windowAndTabManagement";
        l10nId = "zen-window-new-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
        };
        action = "History:UndoCloseWindow";
        disabled = true;
        reserved = false;
        internal = false;
      }
      {
        id = "key_restoreLastClosedTabOrWindowOrSession";
        key = "t";
        keycode = null;
        group = "windowAndTabManagement";
        l10nId = "zen-restore-last-closed-tab-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "History:RestoreLastClosedTabOrWindowOrSession";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_quitApplication";
        key = "";
        keycode = "";
        group = "windowAndTabManagement";
        l10nId = "zen-quit-app-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_quitApplication";
        disabled = false;
        reserved = true;
        internal = false;
      }
      {
        id = "key_sanitize";
        keycode = "VK_DELETE";
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "Tools:Sanitize";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_screenshot";
        key = "s";
        keycode = null;
        group = "mediaAndDisplay";
        l10nId = "zen-screenshot-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "Browser:Screenshot";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_privatebrowsing";
        key = "n";
        keycode = "";
        group = "navigation";
        l10nId = "zen-private-browsing-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "Tools:PrivateBrowsing";
        disabled = false;
        reserved = true;
        internal = false;
      }
      {
        id = "key_switchTextDirection";
        key = "x";
        keycode = null;
        group = "mediaAndDisplay";
        l10nId = "zen-bidi-switch-direction-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "cmd_switchTextDirection";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_showAllTabs";
        keycode = "VK_TAB";
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = null;
        key = "";
        keycode = null;
        group = "other";
        l10nId = "zen-full-zoom-reset-shortcut-alt";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_fullZoomReset";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_fullZoomReset";
        key = "0";
        keycode = null;
        group = "mediaAndDisplay";
        l10nId = "zen-full-zoom-reset-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_fullZoomReset";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = null;
        key = "";
        keycode = null;
        group = "other";
        l10nId = "zen-full-zoom-enlarge-shortcut-alt2";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_fullZoomEnlarge";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = null;
        key = "=";
        keycode = null;
        group = "other";
        l10nId = "zen-full-zoom-enlarge-shortcut-alt";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_fullZoomEnlarge";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_fullZoomEnlarge";
        key = "+";
        keycode = null;
        group = "mediaAndDisplay";
        l10nId = "zen-full-zoom-enlarge-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_fullZoomEnlarge";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = null;
        key = "";
        keycode = null;
        group = "other";
        l10nId = "zen-full-zoom-reduce-shortcut-alt-b";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_fullZoomReduce";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = null;
        key = "_";
        keycode = null;
        group = "other";
        l10nId = "zen-full-zoom-reduce-shortcut-alt-a";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_fullZoomReduce";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_fullZoomReduce";
        key = "-";
        keycode = null;
        group = "mediaAndDisplay";
        l10nId = "zen-full-zoom-reduce-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_fullZoomReduce";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_gotoHistory";
        key = "h";
        keycode = null;
        group = "navigation";
        l10nId = "zen-history-sidebar-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "toggleSidebarKb";
        key = "z";
        keycode = null;
        group = "other";
        l10nId = "zen-toggle-sidebar-shortcut";
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "viewGenaiChatSidebarKb";
        key = "x";
        keycode = null;
        group = "other";
        l10nId = "zen-ai-chatbot-sidebar-shortcut";
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_stop";
        key = "";
        keycode = "";
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "Browser:Stop";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "viewBookmarksToolbarKb";
        key = "b";
        keycode = null;
        group = "other";
        l10nId = "zen-bookmark-show-toolbar-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "viewBookmarksSidebarKb";
        key = "b";
        keycode = null;
        group = "other";
        l10nId = "zen-bookmark-show-sidebar-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "manBookmarkKb";
        key = "o";
        keycode = null;
        group = "historyAndBookmarks";
        l10nId = "zen-bookmark-show-library-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "Browser:ShowAllBookmarks";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "bookmarkAllTabsKb";
        key = "";
        keycode = "";
        group = "historyAndBookmarks";
        l10nId = "zen-bookmark-this-page-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "addBookmarkAsKb";
        key = "d";
        keycode = null;
        group = "historyAndBookmarks";
        l10nId = "zen-bookmark-this-page-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "Browser:AddBookmarkAs";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = null;
        keycode = "VK_F3";
        group = "other";
        l10nId = "zen-search-find-again-shortcut-prev";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = false;
        };
        action = "cmd_findPrevious";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = null;
        keycode = "VK_F3";
        group = "other";
        l10nId = "zen-search-find-again-shortcut-alt";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_findAgain";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_findPrevious";
        key = "g";
        keycode = null;
        group = "searchAndFind";
        l10nId = "zen-search-find-again-shortcut-prev";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "cmd_findPrevious";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_findAgain";
        key = "g";
        keycode = null;
        group = "searchAndFind";
        l10nId = "zen-search-find-again-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_findAgain";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_find";
        key = "f";
        keycode = null;
        group = "searchAndFind";
        l10nId = "zen-find-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_find";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_viewInfo";
        key = "i";
        keycode = null;
        group = "pageOperations";
        l10nId = "zen-page-info-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "View:PageInfo";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_viewSource";
        key = "u";
        keycode = null;
        group = "pageOperations";
        l10nId = "zen-page-source-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "View:PageSource";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_aboutProcesses";
        keycode = "VK_ESCAPE";
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = false;
        };
        action = "View:AboutProcesses";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_reload_skip_cache";
        key = "r";
        keycode = null;
        group = "navigation";
        l10nId = "zen-nav-reload-shortcut-skip-cache";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "Browser:ReloadSkipCache";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_reload";
        key = "r";
        keycode = null;
        group = "navigation";
        l10nId = "zen-nav-reload-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "Browser:Reload";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = null;
        key = "}";
        keycode = null;
        group = "other";
        l10nId = "zen-picture-in-picture-toggle-shortcut-alt";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "View:PictureInPicture";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_togglePictureInPicture";
        key = "]";
        keycode = null;
        group = "pageOperations";
        l10nId = "zen-picture-in-picture-toggle-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "View:PictureInPicture";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_toggleReaderMode";
        key = "r";
        keycode = null;
        group = "pageOperations";
        l10nId = "zen-reader-mode-toggle-shortcut-other";
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "View:ReaderView";
        disabled = true;
        reserved = false;
        internal = false;
      }
      {
        id = "key_exitFullScreen";
        keycode = "VK_F11";
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "View:FullScreen";
        disabled = true;
        reserved = true;
        internal = false;
      }
      {
        id = "key_enterFullScreen";
        keycode = "VK_F11";
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "View:FullScreen";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = null;
        keycode = "VK_F5";
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "Browser:ReloadSkipCache";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "showAllHistoryKb";
        key = "h";
        keycode = null;
        group = "historyAndBookmarks";
        l10nId = "zen-history-show-all-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "Browser:ShowAllHistory";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = null;
        keycode = "VK_F5";
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "Browser:Reload";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "goHome";
        keycode = "VK_HOME";
        group = "navigation";
        l10nId = null;
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "goForwardKb2";
        key = "]";
        keycode = null;
        group = "navigation";
        l10nId = "zen-nav-fwd-shortcut-alt";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "Browser:Forward";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "goBackKb2";
        key = "[";
        keycode = null;
        group = "navigation";
        l10nId = "zen-nav-back-shortcut-alt";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "Browser:Back";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "goForwardKb";
        keycode = "VK_RIGHT";
        group = "navigation";
        l10nId = null;
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "Browser:Forward";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "goBackKb";
        keycode = "VK_LEFT";
        group = "navigation";
        l10nId = null;
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "Browser:Back";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = null;
        keycode = "VK_BACK";
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = false;
        };
        action = "cmd_handleShiftBackspace";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = null;
        keycode = "VK_BACK";
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_handleBackspace";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_selectAll";
        key = "a";
        keycode = null;
        group = "other";
        l10nId = "zen-text-action-select-all-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = true;
      }
      {
        id = "key_delete";
        keycode = "VK_DELETE";
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_delete";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_paste";
        key = "v";
        keycode = null;
        group = "other";
        l10nId = "zen-text-action-paste-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = true;
      }
      {
        id = "key_copy";
        key = "c";
        keycode = null;
        group = "other";
        l10nId = "zen-text-action-copy-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = true;
      }
      {
        id = "key_cut";
        key = "x";
        keycode = null;
        group = "other";
        l10nId = "zen-text-action-cut-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = true;
      }
      {
        id = "key_redo";
        key = "z";
        keycode = null;
        group = "other";
        l10nId = "zen-text-action-undo-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = true;
      }
      {
        id = "key_undo";
        key = "z";
        keycode = null;
        group = "other";
        l10nId = "zen-text-action-undo-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = true;
      }
      {
        id = "key_toggleMute";
        key = "m";
        keycode = null;
        group = "mediaAndDisplay";
        l10nId = "zen-mute-toggle-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_toggleMute";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_closeWindow";
        key = "";
        keycode = "";
        group = "windowAndTabManagement";
        l10nId = "zen-close-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
        };
        action = "cmd_closeWindow";
        disabled = false;
        reserved = true;
        internal = false;
      }
      {
        id = "key_close";
        key = "w";
        keycode = null;
        group = "windowAndTabManagement";
        l10nId = "zen-close-tab-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_close";
        disabled = false;
        reserved = true;
        internal = false;
      }
      {
        id = "printKb";
        key = "p";
        keycode = null;
        group = "pageOperations";
        l10nId = "zen-print-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_print";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_savePage";
        key = "s";
        keycode = null;
        group = "pageOperations";
        l10nId = "zen-save-page-shortcut";
        modifiers = {
          control = false;
          alt = true;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "Browser:SavePage";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "openFileKb";
        key = "";
        keycode = "";
        group = "other";
        l10nId = "zen-file-open-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "Browser:OpenFile";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_openAddons";
        key = "a";
        keycode = null;
        group = "other";
        l10nId = "zen-addons-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "Tools:Addons";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_openDownloads";
        key = "y";
        keycode = null;
        group = "other";
        l10nId = "zen-downloads-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "Tools:Downloads";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_search2";
        key = "j";
        keycode = null;
        group = "searchAndFind";
        l10nId = "zen-search-focus-shortcut-alt";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "Tools:Search";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_search";
        key = "k";
        keycode = null;
        group = "searchAndFind";
        l10nId = "zen-search-focus-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "Tools:Search";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "focusURLBar2";
        key = "d";
        keycode = null;
        group = "pageOperations";
        l10nId = "zen-location-open-shortcut-alt";
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "Browser:OpenLocation";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "focusURLBar";
        key = "l";
        keycode = null;
        group = "pageOperations";
        l10nId = "zen-location-open-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "Browser:OpenLocation";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_newNavigatorTab";
        key = "t";
        keycode = null;
        group = "windowAndTabManagement";
        l10nId = "zen-tab-new-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_newNavigatorTabNoEvent";
        disabled = false;
        reserved = true;
        internal = false;
      }
      {
        id = "key_newNavigator";
        key = "n";
        keycode = null;
        group = "windowAndTabManagement";
        l10nId = "zen-window-new-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_newNavigator";
        disabled = false;
        reserved = true;
        internal = false;
      }
      {
        id = "zen-compact-mode-toggle";
        key = "s";
        keycode = "";
        group = "zen-compact-mode";
        l10nId = "zen-compact-mode-shortcut-toggle";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_toggleCompactModeIgnoreHover";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-compact-mode-show-sidebar";
        key = "s";
        keycode = "";
        group = "zen-compact-mode";
        l10nId = "zen-compact-mode-shortcut-show-sidebar";
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_zenCompactModeShowSidebar";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-workspace-switch-10";
        key = "";
        keycode = "";
        group = "zen-workspace";
        l10nId = "zen-workspace-shortcut-switch-10";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_zenWorkspaceSwitch10";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-workspace-switch-9";
        key = "";
        keycode = "";
        group = "zen-workspace";
        l10nId = "zen-workspace-shortcut-switch-9";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_zenWorkspaceSwitch9";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-workspace-switch-8";
        key = "";
        keycode = "";
        group = "zen-workspace";
        l10nId = "zen-workspace-shortcut-switch-8";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_zenWorkspaceSwitch8";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-workspace-switch-7";
        key = "";
        keycode = "";
        group = "zen-workspace";
        l10nId = "zen-workspace-shortcut-switch-7";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_zenWorkspaceSwitch7";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-workspace-switch-6";
        key = "";
        keycode = "";
        group = "zen-workspace";
        l10nId = "zen-workspace-shortcut-switch-6";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_zenWorkspaceSwitch6";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-workspace-switch-5";
        key = "";
        keycode = "";
        group = "zen-workspace";
        l10nId = "zen-workspace-shortcut-switch-5";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_zenWorkspaceSwitch5";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-workspace-switch-4";
        key = "";
        keycode = "";
        group = "zen-workspace";
        l10nId = "zen-workspace-shortcut-switch-4";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_zenWorkspaceSwitch4";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-workspace-switch-3";
        key = "";
        keycode = "";
        group = "zen-workspace";
        l10nId = "zen-workspace-shortcut-switch-3";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_zenWorkspaceSwitch3";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-workspace-switch-2";
        key = "";
        keycode = "";
        group = "zen-workspace";
        l10nId = "zen-workspace-shortcut-switch-2";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_zenWorkspaceSwitch2";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-workspace-switch-1";
        key = "";
        keycode = "";
        group = "zen-workspace";
        l10nId = "zen-workspace-shortcut-switch-1";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_zenWorkspaceSwitch1";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-workspace-forward";
        key = "";
        keycode = "VK_RIGHT";
        group = "zen-workspace";
        l10nId = "zen-workspace-shortcut-forward";
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_zenWorkspaceForward";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-workspace-backward";
        key = "";
        keycode = "VK_LEFT";
        group = "zen-workspace";
        l10nId = "zen-workspace-shortcut-backward";
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_zenWorkspaceBackward";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-split-view-grid";
        key = "g";
        keycode = "";
        group = "zen-split-view";
        l10nId = "zen-split-view-shortcut-grid";
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_zenSplitViewGrid";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-split-view-vertical";
        key = "v";
        keycode = "";
        group = "zen-split-view";
        l10nId = "zen-split-view-shortcut-vertical";
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_zenSplitViewVertical";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-split-view-horizontal";
        key = "h";
        keycode = "";
        group = "zen-split-view";
        l10nId = "zen-split-view-shortcut-horizontal";
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_zenSplitViewHorizontal";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-split-view-unsplit";
        key = "u";
        keycode = "";
        group = "zen-split-view";
        l10nId = "zen-split-view-shortcut-unsplit";
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_zenSplitViewUnsplit";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-pinned-tab-reset-shortcut";
        key = "";
        keycode = "";
        group = "zen-other";
        l10nId = "zen-pinned-tab-shortcut-reset";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_zenPinnedTabReset";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-toggle-sidebar";
        key = "";
        keycode = "";
        group = "zen-other";
        l10nId = "zen-sidebar-shortcut-toggle";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "cmd_zenToggleSidebar";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-copy-url";
        key = "c";
        keycode = "";
        group = "zen-other";
        l10nId = "zen-text-action-copy-url-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "cmd_zenCopyCurrentURL";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-copy-url-markdown";
        key = "c";
        keycode = "";
        group = "zen-other";
        l10nId = "zen-text-action-copy-url-markdown-shortcut";
        modifiers = {
          control = false;
          alt = true;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "cmd_zenCopyCurrentURLMarkdown";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-toggle-pin-tab";
        key = "d";
        keycode = "";
        group = "zen-other";
        l10nId = "zen-toggle-pin-tab-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "cmd_zenTogglePinTab";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-glance-expand";
        key = "o";
        keycode = "";
        group = "zen-other";
        l10nId = "";
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_zenGlanceExpand";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-new-empty-split-view";
        key = "*";
        keycode = "";
        group = "zen-split-view";
        l10nId = "zen-new-empty-split-view-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "cmd_zenNewEmptySplit";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-close-all-unpinned-tabs";
        key = "k";
        keycode = "";
        group = "zen-workspace";
        l10nId = "zen-close-all-unpinned-tabs-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "cmd_zenCloseUnpinnedTabs";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_accessibility";
        keycode = "VK_F12";
        group = "devTools";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_dom";
        key = "w";
        keycode = null;
        group = "devTools";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_storage";
        keycode = "VK_F9";
        group = "devTools";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_performance";
        keycode = "VK_F5";
        group = "devTools";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_styleeditor";
        keycode = "VK_F7";
        group = "devTools";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = false;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_netmonitor";
        key = "e";
        keycode = null;
        group = "devTools";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_jsdebugger";
        key = "z";
        keycode = null;
        group = "devTools";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_webconsole";
        key = "k";
        keycode = null;
        group = "devTools";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_inspector";
        key = "l";
        keycode = null;
        group = "devTools";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_responsiveDesignMode";
        key = "m";
        keycode = null;
        group = "devTools";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_browserConsole";
        key = "j";
        keycode = null;
        group = "devTools";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_browserToolbox";
        key = "i";
        keycode = null;
        group = "devTools";
        l10nId = null;
        modifiers = {
          control = false;
          alt = true;
          shift = true;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_toggleToolbox";
        key = "i";
        keycode = null;
        group = "devTools";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = null;
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-new-unsynced-window";
        key = "n";
        keycode = "";
        group = "zen-other";
        l10nId = "zen-new-unsynced-window-shortcut";
        modifiers = {
          control = false;
          alt = true;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "cmd_zenNewNavigatorUnsynced";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_reload_skip_cache2";
        keycode = "VK_F5";
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = true;
        };
        action = "Browser:ReloadSkipCache";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "key_reload2";
        keycode = "VK_F5";
        group = "other";
        l10nId = null;
        modifiers = {
          control = false;
          alt = false;
          shift = false;
          meta = false;
          accel = false;
        };
        action = "Browser:Reload";
        disabled = false;
        reserved = false;
        internal = false;
      }
      {
        id = "zen-new-unsynced-window";
        key = "n";
        keycode = "";
        group = "zen-other";
        l10nId = "zen-new-unsynced-window-shortcut";
        modifiers = {
          control = false;
          alt = false;
          shift = true;
          meta = false;
          accel = true;
        };
        action = "cmd_zenNewNavigatorUnsynced";
        disabled = false;
        reserved = false;
        internal = false;
      }
    ];
  };
}
