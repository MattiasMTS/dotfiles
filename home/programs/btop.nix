{
  pkgs,
  lib,
  ...
}:
{
  programs.btop = {
    enable = true;
    settings = {
      theme_background = false;
    };
  };
}
