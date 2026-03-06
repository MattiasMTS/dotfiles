{ pkgs, ... }:
{
  enable = true;
  settings.k9s = {
    skipLatestRevCheck = true;
    noExitOnCtrlC = true;
    ui = {
      enableMouse = true;
      reactive = true;
    };
    logger = {
      tail = 200;
      textWrap = true;
      showTime = true;
    };
  };
}
