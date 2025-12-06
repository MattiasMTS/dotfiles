{ pkgs, lib, ... }:
{
  enable = true;
  enableZshIntegration = true;
  enableNushellIntegration = true;
  nix-direnv.enable = true;
}
