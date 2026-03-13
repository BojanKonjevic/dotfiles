{...}: {
  programs.zathura = {
    enable = true;
    options = {
      default-fg = "rgba(205,214,244,1)";
      default-bg = "rgba(30,30,46,0.75)";
      completion-bg = "rgba(49,50,68,1)";
      completion-fg = "rgba(205,214,244,1)";
      completion-highlight-bg = "rgba(203,166,247,1)";
      completion-highlight-fg = "rgba(30,30,46,1)";
      completion-group-bg = "rgba(24,24,37,1)";
      completion-group-fg = "rgba(205,214,244,1)";
      notification-bg = "rgba(30,30,46,1)";
      notification-fg = "rgba(205,214,244,1)";
      notification-error-bg = "rgba(30,30,46,1)";
      notification-error-fg = "rgba(243,139,168,1)";
      notification-warning-bg = "rgba(30,30,46,1)";
      notification-warning-fg = "rgba(249,226,175,1)";
      recolor = "true";
      recolor-reverse-video = "true";
      recolor-keephue = "true";
      recolor-lightcolor = "rgba(30,30,46,0.75)";
      recolor-darkcolor = "rgba(205,214,244,1)";
      guioptions = "none";
      selection-clipboard = "clipboard";
      render-loading-bg = "rgba(30,30,46,1)";
      render-loading-fg = "rgba(205,214,244,1)";
      highlight-color = "rgba(147,153,178,0.3)";
      highlight-fg = "rgba(205,214,244,1)";
      highlight-active-color = "rgba(203,166,247,0.3)";
    };
    mappings = {
      j = "scroll down";
      k = "scroll up";
    };
  };
}
