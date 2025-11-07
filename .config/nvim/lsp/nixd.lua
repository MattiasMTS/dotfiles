---@type vim.lsp.Config
return {
  cmd = { "nixd" },
  filetypes = { "nix" },
  root_markers = { "flake.nix", ".git" },
  settings = {
    nixd = {
      nixpkgs = {
        -- For flake.
        -- This expression will be interpreted as "nixpkgs" toplevel
        -- Nixd provides package, lib completion/information from it.
        -- Resource Usage: Entries are lazily evaluated, entire nixpkgs takes 200~300MB for just "names".
        -- Package documentation, versions, are evaluated by-need.
        expr = "import (builtins.getFlake(toString ./.)).inputs.nixpkgs { }",
      },
      options = {
        home_manager = {
          expr = 'let flake = builtins.getFlake(toString ./.); in flake.homeConfigurations."mattiassjodin".options',
        },
        darwin = {
          expr = "let flake = builtins.getFlake(toString ./.); in flake.darwinConfigurations.mattiassjodin.options",
        },
      },
    },
  },
}
