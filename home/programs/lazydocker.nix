{ pkgs, ... }:
{
  programs.lazydocker = {
    enable = true;
    settings = {
      gui.theme = {
        activeBorderColor = [
          "red"
          "bold"
        ];
        inactiveBorderColor = [ "blue" ];
      };
    };
  };
}
