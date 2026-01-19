{
  pkgs,
  ...
}:
{
  enable = true;
  enableZshIntegration = true;
  enableNushellIntegration = true;

  settings = {
    # Disable sync - keep history local only
    # auto_sync = false;

    # Search settings
    # search_mode = "fuzzy";
    # filter_mode = "global"; # or "directory" for project-scoped search

    # UI
    style = "compact";
    show_preview = true;
    enter_accept = false;

    # Use vim keybindings since you use vi-mode
    keymap_mode = "vim-normal";

    # Filter out sensitive commands
    # secrets_filter = true;
    # history_filter = [
    #   "^export .*=.*$" # Don't save export with values
    # ];
  };
}
