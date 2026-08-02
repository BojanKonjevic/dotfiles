{...}: {
  programs.zellij = {
    enable = true;
    enableZshIntegration = false;

    settings = {
      default_shell = "zsh";
      pane_frames = false;
      mouse_mode = true;
      scroll_buffer_size = 10000;
      copy_on_select = false;
      simplified_ui = false;
      session_serialization = true;
    };

    extraConfig = ''
      keybinds clear-defaults=true {
        locked {
            bind "Ctrl Shift g" { SwitchToMode "Normal"; }
        }
        resize {
            bind "Ctrl Shift r" { SwitchToMode "Normal"; }
            bind "h" "Left" { Resize "Increase Left"; }
            bind "j" "Down" { Resize "Increase Down"; }
            bind "k" "Up" { Resize "Increase Up"; }
            bind "l" "Right" { Resize "Increase Right"; }
            bind "H" { Resize "Decrease Left"; }
            bind "J" { Resize "Decrease Down"; }
            bind "K" { Resize "Decrease Up"; }
            bind "L" { Resize "Decrease Right"; }
            bind "=" "+" { Resize "Increase"; }
            bind "-" { Resize "Decrease"; }
        }
        pane {
            bind "Ctrl Shift p" { SwitchToMode "Normal"; }
            bind "h" "Left" { MoveFocus "Left"; }
            bind "l" "Right" { MoveFocus "Right"; }
            bind "j" "Down" { MoveFocus "Down"; }
            bind "k" "Up" { MoveFocus "Up"; }
            bind "p" { SwitchFocus; }
            bind "n" { NewPane; SwitchToMode "Normal"; }
            bind "d" { NewPane "Down"; SwitchToMode "Normal"; }
            bind "r" { NewPane "Right"; SwitchToMode "Normal"; }
            bind "s" { NewPane "stacked"; SwitchToMode "Normal"; }
            bind "x" { CloseFocus; SwitchToMode "Normal"; }
            bind "f" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
            bind "z" { TogglePaneFrames; SwitchToMode "Normal"; }
            bind "w" { ToggleFloatingPanes; SwitchToMode "Normal"; }
            bind "e" { TogglePaneEmbedOrFloating; SwitchToMode "Normal"; }
            bind "c" { SwitchToMode "RenamePane"; PaneNameInput 0;}
            bind "i" { TogglePanePinned; SwitchToMode "Normal"; }
        }
        tab {
            bind "Ctrl Shift t" { SwitchToMode "Normal"; }
            bind "r" { SwitchToMode "RenameTab"; TabNameInput 0; }
            bind "h" "Left" "Up" "k" { GoToPreviousTab; }
            bind "l" "Right" "Down" "j" { GoToNextTab; }
            bind "n" { NewTab; SwitchToMode "Normal"; }
            bind "x" { CloseTab; SwitchToMode "Normal"; }
            bind "s" { ToggleActiveSyncTab; SwitchToMode "Normal"; }
            bind "b" { BreakPane; SwitchToMode "Normal"; }
            bind "]" { BreakPaneRight; SwitchToMode "Normal"; }
            bind "[" { BreakPaneLeft; SwitchToMode "Normal"; }
            bind "1" { GoToTab 1; SwitchToMode "Normal"; }
            bind "2" { GoToTab 2; SwitchToMode "Normal"; }
            bind "3" { GoToTab 3; SwitchToMode "Normal"; }
            bind "4" { GoToTab 4; SwitchToMode "Normal"; }
            bind "5" { GoToTab 5; SwitchToMode "Normal"; }
            bind "6" { GoToTab 6; SwitchToMode "Normal"; }
            bind "7" { GoToTab 7; SwitchToMode "Normal"; }
            bind "8" { GoToTab 8; SwitchToMode "Normal"; }
            bind "9" { GoToTab 9; SwitchToMode "Normal"; }
            bind "Tab" { ToggleTab; }
        }
        scroll {
            bind "Ctrl Shift s" { SwitchToMode "Normal"; }
            bind "e" { EditScrollback; SwitchToMode "Normal"; }
            bind "s" { SwitchToMode "EnterSearch"; SearchInput 0; }
            bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
            bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
        }
        search {
            bind "Ctrl Shift s" { SwitchToMode "Normal"; }
            bind "Ctrl c" { ScrollToBottom; SwitchToMode "Normal"; }
            bind "j" "Down" { ScrollDown; }
            bind "k" "Up" { ScrollUp; }
            bind "Ctrl f" "PageDown" "Right" "l" { PageScrollDown; }
            bind "Ctrl b" "PageUp" "Left" "h" { PageScrollUp; }
            bind "d" { HalfPageScrollDown; }
            bind "u" { HalfPageScrollUp; }
            bind "n" { Search "down"; }
            bind "p" { Search "up"; }
            bind "c" { SearchToggleOption "CaseSensitivity"; }
            bind "w" { SearchToggleOption "Wrap"; }
            bind "o" { SearchToggleOption "WholeWord"; }
        }
        entersearch {
            bind "Ctrl c" "Esc" { SwitchToMode "Scroll"; }
            bind "Enter" { SwitchToMode "Search"; }
        }
        renametab {
            bind "Ctrl c" { SwitchToMode "Normal"; }
            bind "Esc" { UndoRenameTab; SwitchToMode "Tab"; }
        }
        renamepane {
            bind "Ctrl c" { SwitchToMode "Normal"; }
            bind "Esc" { UndoRenamePane; SwitchToMode "Pane"; }
        }
        session {
            bind "Ctrl Shift o" { SwitchToMode "Normal"; }
            bind "Ctrl Shift s" { SwitchToMode "Scroll"; }
            bind "d" { Detach; }
            bind "w" {
                LaunchOrFocusPlugin "session-manager" { floating true; move_to_focused_tab true; };
                SwitchToMode "Normal"
            }
            bind "c" {
                LaunchOrFocusPlugin "configuration" { floating true; move_to_focused_tab true; };
                SwitchToMode "Normal"
            }
            bind "p" {
                LaunchOrFocusPlugin "plugin-manager" { floating true; move_to_focused_tab true; };
                SwitchToMode "Normal"
            }
            bind "a" {
                LaunchOrFocusPlugin "zellij:about" { floating true; move_to_focused_tab true; };
                SwitchToMode "Normal"
            }
            bind "s" {
                LaunchOrFocusPlugin "zellij:share" { floating true; move_to_focused_tab true; };
                SwitchToMode "Normal"
            }
            bind "l" {
                LaunchOrFocusPlugin "zellij:layout-manager" { floating true; move_to_focused_tab true; };
                SwitchToMode "Normal"
            }
        }
        tmux {
            bind "[" { SwitchToMode "Scroll"; }
            bind "Ctrl Shift b" { Write 2; SwitchToMode "Normal"; }
            bind "\"" { NewPane "Down"; SwitchToMode "Normal"; }
            bind "%" { NewPane "Right"; SwitchToMode "Normal"; }
            bind "z" { ToggleFocusFullscreen; SwitchToMode "Normal"; }
            bind "c" { NewTab; SwitchToMode "Normal"; }
            bind "," { SwitchToMode "RenameTab"; }
            bind "p" { GoToPreviousTab; SwitchToMode "Normal"; }
            bind "n" { GoToNextTab; SwitchToMode "Normal"; }
            bind "Left" { MoveFocus "Left"; SwitchToMode "Normal"; }
            bind "Right" { MoveFocus "Right"; SwitchToMode "Normal"; }
            bind "Down" { MoveFocus "Down"; SwitchToMode "Normal"; }
            bind "Up" { MoveFocus "Up"; SwitchToMode "Normal"; }
            bind "h" { MoveFocus "Left"; SwitchToMode "Normal"; }
            bind "l" { MoveFocus "Right"; SwitchToMode "Normal"; }
            bind "j" { MoveFocus "Down"; SwitchToMode "Normal"; }
            bind "k" { MoveFocus "Up"; SwitchToMode "Normal"; }
            bind "o" { FocusNextPane; }
            bind "d" { Detach; }
            bind "Space" { NextSwapLayout; }
            bind "x" { CloseFocus; SwitchToMode "Normal"; }
        }
        shared_except "locked" {
            bind "Super c" { Copy; }
            bind "Ctrl Shift g" { SwitchToMode "Locked"; }
            bind "Ctrl Shift q" { Quit; }
            bind "Ctrl Shift 1" { GoToTab 1; }
            bind "Ctrl Shift 2" { GoToTab 2; }
            bind "Ctrl Shift 3" { GoToTab 3; }
            bind "Ctrl Shift 4" { GoToTab 4; }
            bind "Ctrl Shift 5" { GoToTab 5; }
            bind "Ctrl Shift 6" { GoToTab 6; }
            bind "Ctrl Shift 7" { GoToTab 7; }
            bind "Ctrl Shift 8" { GoToTab 8; }
            bind "Ctrl Shift 9" { GoToTab 9; }
            bind "Ctrl Shift n" { NewPane; }
            bind "Ctrl Shift x" { CloseFocus; }
            bind "Ctrl Shift f" { ToggleFocusFullscreen; }
            bind "Ctrl Shift w" {
                LaunchOrFocusPlugin "session-manager" { floating true; move_to_focused_tab true; };
                SwitchToMode "Normal"
            }
            bind "Alt f" { ToggleFloatingPanes; }
            bind "Alt n" { NewPane; }
            bind "Alt i" { MoveTab "Left"; }
            bind "Alt o" { MoveTab "Right"; }
            bind "Ctrl Shift h" "Ctrl Shift Left" { MoveFocus "Left"; }
            bind "Ctrl Shift j" "Ctrl Shift Down" { MoveFocus "Down"; }
            bind "Ctrl Shift k" "Ctrl Shift Up" { MoveFocus "Up"; }
            bind "Ctrl Shift l" "Ctrl Shift Right" { MoveFocus "Right"; }
            bind "Alt h" "Alt Left" { MoveFocusOrTab "Left"; }
            bind "Alt l" "Alt Right" { MoveFocusOrTab "Right"; }
            bind "Alt j" "Alt Down" { MoveFocus "Down"; }
            bind "Alt k" "Alt Up" { MoveFocus "Up"; }
            bind "Alt =" "Alt +" { Resize "Increase"; }
            bind "Alt -" { Resize "Decrease"; }
            bind "Alt [" { PreviousSwapLayout; }
            bind "Alt ]" { NextSwapLayout; }
            bind "Alt p" { TogglePaneInGroup; }
            bind "Alt Shift p" { ToggleGroupMarking; }
        }
        shared_except "normal" "locked" {
            bind "Enter" "Esc" { SwitchToMode "Normal"; }
        }
        shared_except "pane" "locked" {
            bind "Ctrl Shift p" { SwitchToMode "Pane"; }
        }
        shared_except "resize" "locked" {
            bind "Ctrl Shift r" { SwitchToMode "Resize"; }
        }
        shared_except "scroll" "locked" {
            bind "Ctrl Shift s" { SwitchToMode "Scroll"; }
        }
        shared_except "session" "locked" {
            bind "Ctrl Shift o" { SwitchToMode "Session"; }
        }
        shared_except "tab" "locked" {
            bind "Ctrl Shift t" { SwitchToMode "Tab"; }
        }
        shared_except "tmux" "locked" {
            bind "Ctrl Shift b" { SwitchToMode "Tmux"; }
        }
      }
    '';
  };
}
