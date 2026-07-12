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

  # ── Keys to block when pressed with Cmd ─────────────────────────────────────
  blockedKeys = [
    {
      key = "q";
      desc = "Disable Cmd+Q (quit) — use Rift mod+Shift+Q instead";
    }
    {
      key = "w";
      desc = "Disable Cmd+W (close window) — use Rift mod+Q instead";
    }
    {
      key = "n";
      desc = "Disable Cmd+N (new window) — use Rift mod+N instead";
    }
    {
      key = "m";
      desc = "Disable Cmd+M (minimize) — Rift owns window management";
    }
    {
      key = "h";
      desc = "Disable Cmd+H (hide) — Rift owns window management";
    }
  ];

  karabinerJson = "${config.xdg.configHome}/karabiner/karabiner.json";

  hasExceptions = builtins.length appExceptions > 0;

  # One rule per key so each is independently toggleable in Karabiner's UI
  rules =
    map ({
      key,
      desc,
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
      conditions = lib.optionals hasExceptions [
        {
          type = "frontmost_application_unless";
          bundle_identifiers = appExceptions;
        }
      ];
      manipulatorWithConditions =
        if hasExceptions
        then manipulator // {inherit conditions;}
        else manipulator;
    in {
      description = desc;
      manipulators = [manipulatorWithConditions];
    })
    blockedKeys;
in {
  home.packages = [pkgs.jq];

  xdg.configFile."karabiner/assets/complex_modifications/nix-cmd-block.json" = {
    text = builtins.toJSON {
      title = "Block native Cmd shortcuts (Rift owns window management via mod)";
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
