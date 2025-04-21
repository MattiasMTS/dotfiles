{ pkgs, ... }: {
  enable = true;

  settings = {
    notARepository = "quit";
    gui = {
      showBottomLine = false;
      border = "rounded";
      nerdFontsVersion = 3;
    };
    os.editPreset = "nvim";
    git.overrideGpg = true;
  };

}

