{ pkgs, ... }:
{
  enable = true;

  settings = {
    notARepository = "quit";
    gui = {
      showBottomLine = true;
      border = "rounded";
      nerdFontsVersion = 3;
      skipDiscardChangeWarning = false;
      skipStashWarning = false;
      mainPanelSplitMode = "flexible";
      commitLength.show = true;
      splitDiff = "auto";
      commandLogSize = 6;
      sidePanelWidth = 0.25;
    };
    os.editPreset = "nvim-remote";
    git.overrideGpg = true;
    git.pager = {
      colorArg = "always";
      pager = "difft --color always";
      useConfig = false;
    };
  };

}
