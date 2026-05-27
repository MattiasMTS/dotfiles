{ pkgs, ... }:
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings."*" = {
      UseKeychain = "yes";
      IdentityFile = "~/.ssh/id_ed25519";
      AddKeysToAgent = "yes";
    };
  };
}
