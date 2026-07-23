{
  config,
  lib,
  pkgs,
  ...
}: let
  # ── Per-app exceptions ──────────────────────────────────────────────────────
  # Apps that should keep native Cmd+key behavior. Add bundle identifiers here
  # using regex format (e.g. "^com\\.mitchellh\\.ghostty$").
  # Start empty — no exceptions; all apps have Cmd+Q/W/N/M/H blocked.
  # Rift's own mod+Q/modShift+Q/mod+N go through ksd's synthetic CGEventPost,
  # which bypasses Karabiner's HID-level grabber, so those still work.
  appExceptions = [];

  finderBundleId = "^com\\.apple\\.finder$";
  terminalBundleId = "^com\\.mitchellh\\.ghostty$";

  # ── Keys to block when pressed with Cmd ─────────────────────────────────────
  # "excludeFinder = true" is used for keys that Finder also wants to reclaim
  # for its own Cmd+hjkl navigation below (currently just "h" — Cmd+M and
  # Cmd+H would otherwise collide with the Finder-specific rules).
  blockedKeys = [
    {
      key = "q";
      desc = "Disable Cmd+Q (quit) — use Rift mod+Shift+Q instead";
      excludeFinder = false;
      excludeTerminal = true;
    }
    {
      key = "w";
      desc = "Disable Cmd+W (close window) — use Rift mod+Q instead";
      excludeFinder = false;
    }
    {
      key = "n";
      desc = "Disable Cmd+N (new window) — use Rift mod+N instead";
      excludeFinder = false;
    }
    {
      key = "m";
      desc = "Disable Cmd+M (minimize) — Rift owns window management";
      excludeFinder = false;
    }
    {
      key = "h";
      desc = "Disable Cmd+H (hide) — Rift owns window management";
      excludeFinder = true; # Finder reclaims Cmd+H for "navigate left"
      # No excludeTerminal here: Ghostty's Cmd+H is handled by
      # ghosttyCmdHRule below, which remaps it to Cmd+Ctrl+H *before*
      # this block rule would ever see it. If that rule is ever removed,
      # this block rule falls back to eating Cmd+H in Ghostty too.
    }
  ];

  karabinerJson = "${config.xdg.configHome}/karabiner/karabiner.json";
  hasExceptions = builtins.length appExceptions > 0;

  # One rule per key so each is independently toggleable in Karabiner's UI
  blockRules =
    map ({
      key,
      desc,
      excludeFinder,
      excludeTerminal ? false,
    }: let
      manipulator = {
        type = "basic";
        from = {
          key_code = key;
          modifiers = {
            mandatory = ["command"];
            optional = ["any"];
          };
        };
      };
      excludedBundleIds =
        appExceptions
        ++ lib.optionals excludeFinder [finderBundleId]
        ++ lib.optionals excludeTerminal [terminalBundleId];
      hasAnyExclusions = builtins.length excludedBundleIds > 0;
      conditions = lib.optionals hasAnyExclusions [
        {
          type = "frontmost_application_unless";
          bundle_identifiers = excludedBundleIds;
        }
      ];
      manipulatorWithConditions =
        if hasAnyExclusions
        then manipulator // {inherit conditions;}
        else manipulator;
    in {
      description = desc;
      manipulators = [manipulatorWithConditions];
    })
    blockedKeys;

  # ── Ghostty: Cmd+H -> Cmd+Ctrl+H instead of native hide ─────────────────────
  # Karabiner intercepts Cmd+H at the HID level before macOS ever sees it,
  # and — only when Ghostty is frontmost — rewrites it to Cmd+Ctrl+H. Ghostty
  # passes that through to nvim as a distinct chord nvim can bind
  # (<D-C-h> -> <C-w><C-h>), so the native "hide application" behavior never
  # fires and nvim still gets a usable Cmd-flavored keystroke for window nav.
  # This must be matched before the generic "h" block rule, so it's placed
  # first in `rules` below.
  ghosttyCmdHRule = {
    description = "Ghostty: Cmd+H -> Cmd+Ctrl+H (avoid native hide, let nvim bind it)";
    manipulators = [
      {
        type = "basic";
        from = {
          key_code = "h";
          modifiers = {
            mandatory = ["command"];
            optional = ["any"];
          };
        };
        to = [
          {
            key_code = "h";
            modifiers = ["left_command" "left_control"];
          }
        ];
        conditions = [
          {
            type = "frontmost_application_if";
            bundle_identifiers = [terminalBundleId];
          }
        ];
      }
    ];
  };

  # ── Finder: Enter opens instead of renaming ─────────────────────────────────
  finderEnterOpensRule = {
    description = "Finder: Enter opens (Cmd+Down) instead of rename";
    manipulators = [
      {
        type = "basic";
        from = {
          key_code = "return_or_enter";
          modifiers = {optional = ["any"];};
        };
        to = [
          {
            key_code = "down_arrow";
            modifiers = ["command"];
          }
        ];
        conditions = [
          {
            type = "frontmost_application_if";
            bundle_identifiers = [finderBundleId];
          }
        ];
      }
    ];
  };

  # ── Finder: Cmd+hjkl added alongside arrow keys ─────────────────────────────
  # These ADD Cmd+h/j/k/l as extra bindings; the physical arrow keys keep
  # working too since nothing remaps them away.
  finderHjklRule = {
    description = "Finder: Cmd+hjkl navigates like arrow keys";
    manipulators = let
      finderCondition = [
        {
          type = "frontmost_application_if";
          bundle_identifiers = [finderBundleId];
        }
      ];
      mk = {
        from_key,
        to_key,
      }: {
        type = "basic";
        from = {
          key_code = from_key;
          modifiers = {
            mandatory = ["command"];
            optional = ["any"];
          };
        };
        to = [{key_code = to_key;}];
        conditions = finderCondition;
      };
    in [
      (mk {
        from_key = "h";
        to_key = "left_arrow";
      })
      (mk {
        from_key = "j";
        to_key = "down_arrow";
      })
      (mk {
        from_key = "k";
        to_key = "up_arrow";
      })
      (mk {
        from_key = "l";
        to_key = "right_arrow";
      })
    ];
  };

  capsLockPaneNavRule = {
    description = "Caps Lock (held) -> Ctrl+Shift, used for Zellij pane nav";
    manipulators = [
      {
        type = "basic";
        from = {
          key_code = "caps_lock";
          modifiers = {optional = ["any"];};
        };
        to = [
          {
            key_code = "left_control";
            modifiers = ["left_shift"];
          }
        ];
      }
    ];
  };

  rules =
    [ghosttyCmdHRule capsLockPaneNavRule]
    ++ blockRules
    ++ [
      finderEnterOpensRule
      finderHjklRule
    ];
in {
  home.packages = [pkgs.jq];
  xdg.configFile."karabiner/assets/complex_modifications/nix-cmd-block.json" = {
    text = builtins.toJSON {
      title = "Block native Cmd shortcuts (Rift owns window management via mod) + Finder navigation";
      inherit rules;
    };
  };
  home.activation.karabinerApplySettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    RULES_JSON=${lib.escapeShellArg (builtins.toJSON rules)}
    if [ -f "${karabinerJson}" ]; then
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq \
        --argjson rules "$RULES_JSON" \
        '.global.show_in_menu_bar = false
         | .profiles |= map(if .selected then .complex_modifications.rules = $rules else . end)' \
        "${karabinerJson}" > "${karabinerJson}.nixtmp" \
      && $DRY_RUN_CMD mv "${karabinerJson}.nixtmp" "${karabinerJson}"
    else
      $DRY_RUN_CMD mkdir -p "$(dirname "${karabinerJson}")"
      $DRY_RUN_CMD ${pkgs.jq}/bin/jq -n \
        --argjson rules "$RULES_JSON" \
        '{
           global: { show_in_menu_bar: false },
           profiles: [
             {
               name: "Default profile",
               selected: true,
               complex_modifications: { rules: $rules }
             }
           ]
         }' > "${karabinerJson}.nixtmp" \
      && $DRY_RUN_CMD mv "${karabinerJson}.nixtmp" "${karabinerJson}"
    fi
  '';
}
