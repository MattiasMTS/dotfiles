{ pkgs, ... }:
{
  enable = true;
  enableDefaultConfig = false;
  matchBlocks."*" = {
    extraOptions = {
      UseKeychain = "yes";
    };
    identityFile = "~/.ssh/id_ed25519";
  };
  matchBlocks."*".addKeysToAgent = "yes";
}
