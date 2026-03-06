{
  config,
  pkgs,
  lib,
  inputs,
  username,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  dotfilesPath = "/Users/${username}/src/github.com/projects/dotfiles";
  nvim-nightly = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
  blink-fuzzy-lib = inputs.blink-cmp.packages.${pkgs.system}.blink-fuzzy-lib;
  peon-ping-pkg = inputs.peon-ping.packages.${pkgs.system}.peon-ping;
  treesitter-grammars = pkgs.symlinkJoin {
    name = "nvim-treesitter-grammars";
    paths = pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies;
  };
in
{
  imports = [ inputs.peon-ping.homeManagerModules.default ];

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

  # applications/programs
  programs = {
    neovim = {
      enable = true;
      package = nvim-nightly;
      defaultEditor = true;
      vimdiffAlias = true;
    };
    zsh = import ./programs/zsh.nix { inherit pkgs username; };
    starship = import ./programs/starship.nix { inherit pkgs; };
    git = import ./programs/git.nix { inherit username lib; };
    jujutsu = import ./programs/jujutsu.nix { inherit username lib; };
    tmux = import ./programs/tmux.nix { inherit pkgs dotfilesPath; };
    fzf = import ./programs/fzf.nix { inherit pkgs lib; };
    direnv = import ./programs/direnv.nix { inherit pkgs lib; };
    zoxide = import ./programs/zoxide.nix { inherit pkgs; };
    atuin = import ./programs/atuin.nix { inherit pkgs; };
    nushell = import ./programs/nushell.nix { inherit pkgs username; };
    go = import ./programs/go.nix { inherit pkgs username; };
    java = import ./programs/java.nix { inherit pkgs; };
    lazygit = import ./programs/lazygit.nix { inherit pkgs; };
    gh = import ./programs/gh.nix { inherit pkgs; };
    ssh = import ./programs/ssh.nix { inherit pkgs; };
    aerospace = import ./programs/aerospace.nix { inherit pkgs lib; };
    claude-code = import ./programs/claude-code.nix {
      inherit
        pkgs
        lib
        inputs
        username
        ;
      peon-ping = peon-ping-pkg;
    };
    peon-ping = import ./programs/peon-ping.nix { inherit pkgs inputs lib; };
    bat.enable = true;
    k9s = import ./programs/k9s.nix { inherit pkgs; };
    ripgrep.enable = true;
    jq.enable = true;
  };

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
    amp-cli
    parallel
    nixd

    kubectl
    kubectx
    kubernetes-helm
    kustomize

    tflint
    trivy
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
    prettier

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
