{
  pkgs,
  lib,
  ...
}:
{
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    enableNushellIntegration = false;
    nix-direnv.enable = true;
    config = {
      hide_env_diff = true;
    };
  };
}
