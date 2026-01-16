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
  git-worktree-session = import ../pkgs/git-worktree-session.nix { inherit pkgs; };
  blink-fuzzy-lib = inputs.blink-cmp.packages.${pkgs.system}.blink-fuzzy-lib;
in
{
  programs.home-manager.enable = true;
  home.stateVersion = "25.05";

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  xdg.enable = true;

  # packages managed outside of home-manager
  xdg.configFile.nvim.source = mkOutOfStoreSymlink "${dotfilesPath}/.config/nvim";
  xdg.configFile.ghostty.source = mkOutOfStoreSymlink "${dotfilesPath}/.config/ghostty";
  xdg.configFile.sesh.source = mkOutOfStoreSymlink "${dotfilesPath}/.config/sesh";
  xdg.configFile.worktrunk.source = mkOutOfStoreSymlink "${dotfilesPath}/.config/worktrunk";

  # Symlink blink.cmp fuzzy library built via Nix to where lazy.nvim expects it
  home.file.".local/share/nvim/lazy/blink.cmp/target/release/libblink_cmp_fuzzy.dylib".source =
    "${blink-fuzzy-lib}/lib/libblink_cmp_fuzzy.dylib";

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
    tmux = import ./programs/tmux.nix { inherit pkgs; };
    fzf = import ./programs/fzf.nix { inherit pkgs lib; };
    direnv = import ./programs/direnv.nix { inherit pkgs lib; };
    zoxide = import ./programs/zoxide.nix { inherit pkgs; };
    nushell = import ./programs/nushell.nix { inherit pkgs username; };
    go = import ./programs/go.nix { inherit pkgs username; };
    java = import ./programs/java.nix { inherit pkgs; };
    lazygit = import ./programs/lazygit.nix { inherit pkgs; };
    gh = import ./programs/gh.nix { inherit pkgs; };
    ssh = import ./programs/ssh.nix { inherit pkgs; };
    aerospace = import ./programs/aerospace.nix { inherit pkgs lib; };
    claude-code = import ./programs/claude-code.nix { inherit pkgs lib inputs; };
    bat.enable = true;
    k9s.enable = true;
    ripgrep.enable = true;
    jq.enable = true;
  };

  # user specific packages instead of system wide
  home.packages = [
    git-worktree-session
  ]
  ++ (with pkgs; [
    inputs.worktrunk.packages.${pkgs.system}.worktrunk
    devenv
    tree-sitter
    fzf
    fd
    delta
    difftastic
    sesh
    tree
    nixfmt
    presenterm
    clang
    # opencode
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
    spacectl
    clickhouse

    python313
    python313Packages.ipython

    pnpm
    nodejs_24
    bun
    vtsls
    deno
    nodePackages.vscode-json-languageserver
    prettier

    duckdb
    uv
    ty
    ruff
    pre-commit
    graphite-cli

    (google-cloud-sdk.withExtraComponents (
      with pkgs.google-cloud-sdk.components;
      [
        gke-gcloud-auth-plugin
      ]
    ))
    google-cloud-sql-proxy

    delve
    docker
    docker-compose
    dockerfile-language-server
    docker-compose-language-service

    # LSP execs, formatter and linters for neovim
    yaml-language-server
    yamllint

    vim-language-server
    lua-language-server
    stylua
    bash-language-server
    basedpyright
    gopls
    templ
    golines
    gofumpt
    golangci-lint
    gosec
    nil
    helm-ls
    tofu-ls
  ]);
}
