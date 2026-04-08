{...}: {
  flake.homeModules.zen-browser = {
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
      user_pref("font.name.monospace.x-western", "${theme.fontName}");
      user_pref("font.name.sans-serif.x-western", "${theme.fontName}");
      user_pref("font.name.serif.x-western", "${theme.fontName}");
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
  };
}
