{ pkgs, ... }:
{
  enable = true;
  enableZshIntegration = true;
  enableNushellIntegration = true;
  options = [ "--cmd cd" ];
}
