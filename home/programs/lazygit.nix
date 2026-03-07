{ pkgs, ... }:
{
  programs.lazygit = {
    enable = true;
    enableZshIntegration = false; # some weird lg function
    enableNushellIntegration = false;

    settings = {
      notARepository = "quit";
      gui = {
        showBottomLine = true;
        border = "rounded";
        nerdFontsVersion = "3";
        skipDiscardChangeWarning = false;
        skipStashWarning = false;
        mainPanelSplitMode = "flexible";
        commitLength.show = true;
        splitDiff = "auto";
        commandLogSize = 6;
        sidePanelWidth = 0.20;
      };
      os.editPreset = "nvim-remote";
      git = {
        overrideGpg = true;
        pagers = [
          {
            pager = "delta --dark --paging=never --line-numbers --hyperlinks --hyperlinks-file-link-format=\"lazygit-edit://{path}:{line}\"";
          }
        ];
        log.order = "default";
      };
    };
  };
}
