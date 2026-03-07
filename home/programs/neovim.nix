{
  inputs,
  pkgs,
  ...
}:
let
  nvim-nightly = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
in
{
  programs.neovim = {
    enable = true;
    package = nvim-nightly;
    defaultEditor = true;
    vimdiffAlias = true;
  };
}
