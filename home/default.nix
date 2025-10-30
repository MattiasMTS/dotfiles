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

  # Custom packages
  # sqlmesh_lsp = pkgs.callPackage ../pkgs/sqlmesh.nix { };
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

  # applications/programs
  programs = {
    neovim = {
      enable = true;
      package = nvim-nightly;
      defaultEditor = true;

      withPython3 = true;
      withNodeJs = true;

      vimdiffAlias = true;
      vimAlias = true;
    };
    zsh = import ./programs/zsh.nix {
      inherit
        config
        pkgs
        lib
        username
        ;
    };
    starship = import ./programs/starship.nix { inherit pkgs; };
    git = import ./programs/git.nix { inherit username lib; };
    jujutsu = import ./programs/jujutsu.nix { inherit username lib; };
    tmux = import ./programs/tmux.nix { inherit pkgs; };
    fzf = import ./programs/fzf.nix { inherit pkgs lib; };
    direnv = import ./programs/direnv.nix { inherit pkgs lib; };
    zoxide = (import ./programs/zoxide.nix { inherit pkgs; });
    go = import ./programs/go.nix { inherit pkgs username; };
    java = import ./programs/java.nix { inherit pkgs; };
    lazygit = import ./programs/lazygit.nix { inherit pkgs; };
    gh = import ./programs/gh.nix { inherit pkgs; };
    ssh = import ./programs/ssh.nix { inherit pkgs; };
    aerospace = import ./programs/aerospace.nix { inherit pkgs lib; };
    bat.enable = true;
    k9s.enable = true;
    ripgrep.enable = true;
    jq.enable = true;
  };

  # user specific packages instead of system wide
  home.packages = with pkgs; [
    devenv
    tree-sitter
    fzf
    fd
    delta
    sesh
    tree
    nixfmt-rfc-style
    presenterm
    clang
    claude-code
    jjui

    kubectl
    kubectx
    kubernetes-helm
    kustomize
    k3d
    rancher

    terraform
    tflint
    trivy
    opentofu
    spacectl
    grafanactl

    python313
    python313Packages.ipython
    python313Packages.sqlfmt

    # pnpm_9
    nodejs_24
    bun
    vtsls
    deno
    nodePackages.vscode-json-languageserver

    duckdb
    uv
    ruff
    pre-commit
    # sqlmesh_lsp

    awscli2
    (google-cloud-sdk.withExtraComponents (
      with pkgs.google-cloud-sdk.components;
      [
        gke-gcloud-auth-plugin
        package-go-module
        pubsub-emulator
      ]
    ))
    google-cloud-sql-proxy

    docker
    docker-compose
    dockerfile-language-server
    docker-compose-language-service
    colima
    lazydocker

    # protobuf
    # protolint
    # buf

    # LSP execs, formatter and linters for neovim
    yaml-language-server
    yamllint

    vim-language-server
    lua-language-server
    stylua

    bash-language-server

    # pyright
    basedpyright

    gopls
    templ
    golines
    gofumpt
    copilot-language-server

    temporal-cli
    terraform-ls
    nil
    helm-ls
    #markdown-oxide # trying this out
    #steampipe
  ];
}
