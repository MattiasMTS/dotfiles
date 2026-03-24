{
  config,
  pkgs,
  lib,
  inputs,
  username,
  dotfilesPath,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  blink-fuzzy-lib = inputs.blink-cmp.packages.${pkgs.system}.blink-fuzzy-lib;
  treesitter-grammars = pkgs.symlinkJoin {
    name = "nvim-treesitter-grammars";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };
in
{
  imports = [
    inputs.peon-ping.homeManagerModules.default
    ../modules/amp-cli.nix
    ./programs/zsh.nix
    ./programs/starship.nix
    ./programs/git.nix
    ./programs/jujutsu.nix
    ./programs/tmux.nix
    ./programs/fzf.nix
    ./programs/direnv.nix
    ./programs/zoxide.nix
    ./programs/atuin.nix
    ./programs/nushell.nix
    ./programs/go.nix
    ./programs/java.nix
    ./programs/lazygit.nix
    ./programs/gh.nix
    ./programs/ssh.nix
    ./programs/aerospace.nix
    ./programs/claude-code.nix
    ./programs/amp-cli.nix
    ./programs/peon-ping.nix
    ./programs/k9s.nix
    ./programs/neovim.nix
    ./programs/bat.nix
    ./programs/ripgrep.nix
    ./programs/jq.nix
    ./programs/btop.nix
  ];

  programs.home-manager.enable = true;
  home.stateVersion = "25.05";

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  home.sessionPath = [ "${dotfilesPath}/scripts" ];
  xdg.enable = true;

  # packages managed outside of home-manager
  xdg.configFile.nvim.source = mkOutOfStoreSymlink "${dotfilesPath}/.config/nvim";
  xdg.configFile.ghostty.source = mkOutOfStoreSymlink "${dotfilesPath}/.config/ghostty";
  xdg.configFile.worktrunk.source = mkOutOfStoreSymlink "${dotfilesPath}/.config/worktrunk";
  # Symlink blink.cmp fuzzy library built via Nix to where lazy.nvim expects it
  home.file.".local/share/nvim/lazy/blink.cmp/target/release/libblink_cmp_fuzzy.dylib".source =
    "${blink-fuzzy-lib}/lib/libblink_cmp_fuzzy.dylib";
  # Symlink Nix-built tree-sitter grammars (pre-compiled and code-signed for macOS)
  home.file.".local/share/nvim/nix-treesitter-grammars".source = treesitter-grammars;

  # user specific packages instead of system wide
  home.packages = with pkgs; [
    inputs.worktrunk.packages.${pkgs.system}.worktrunk
    tree-sitter
    fzf
    fd
    delta
    difftastic
    tree
    nixfmt
    presenterm
    clang
    codex
    parallel
    nixd

    kubectl
    kubectx
    kubernetes-helm
    kustomize

    tflint
    opentofu
    clickhouse
    lefthook

    python313
    python313Packages.ipython

    pnpm
    nodejs_22
    bun
    vtsls
    deno
    nodePackages.vscode-json-languageserver

    duckdb
    uv
    ty
    ruff
    pyright
    nodePackages.typescript-language-server
    graphite-cli
    cargo

    (google-cloud-sdk.withExtraComponents (
      with pkgs.google-cloud-sdk.components;
      [
        gke-gcloud-auth-plugin
      ]
    ))
    google-cloud-sql-proxy
    gofumpt
    golangci-lint

    delve
    docker
    docker-compose
    yamllint
    lua51Packages.jsregexp
    viddy

    # LSP execs, formatter and linters for neovim
    dockerfile-language-server
    docker-compose-language-service
    yaml-language-server
    rust-analyzer

    vim-language-server
    lua-language-server
    stylua
    bash-language-server
    gopls
    templ
    golines
    nil
    helm-ls
    tofu-ls
    buf
  ];
}
