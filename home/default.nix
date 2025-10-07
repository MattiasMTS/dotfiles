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
  dotfilesPath = "/Users/mattiassjodin/src/github.com/projects/dotfiles";
  nvim-nightly = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
  devenv_1_8_1 = inputs.devenv.packages.${pkgs.system}.devenv;
  # devenv_1_8_1 = pkgs.devenv.overrideAttrs (old: {
  #   version = "1.8.1";
  #   src = pkgs.fetchFromGitHub {
  #     owner = "cachix";
  #     repo = "devenv";
  #     tag = "v1.8.1";
  #     hash = "sha256-YsSFlVWUu4RSYnObqcBJ4Mr3bJVVhuFhaQAktHytBAI=";
  #   };
  #   # cargoHash = "sha256-zJorGAsp5k5oBuXogYqEPVexcNsYCeiTmrQqySd1AGs=";
  #   cargoHash = pkgs.lib.fakeSha256;
  #   # cargoHash = "sha256-41VmzZvoRd2pL5/o6apHztpS2XrL4HGPIJPBkUbPL1I=";
  #
  # });
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
    tmux = import ./programs/tmux.nix { inherit pkgs; };
    fzf = import ./programs/fzf.nix { inherit pkgs lib; };
    direnv = import ./programs/direnv.nix { inherit pkgs lib; };
    zoxide = (import ./programs/zoxide.nix { inherit pkgs; });
    go = import ./programs/go.nix { inherit pkgs username; };
    java = import ./programs/java.nix { inherit pkgs; };
    lazygit = import ./programs/lazygit.nix { inherit pkgs; };
    gh = import ./programs/gh.nix { inherit pkgs; };
    ssh = import ./programs/ssh.nix { inherit pkgs; };
    bat.enable = true;
    k9s.enable = true;
    ripgrep.enable = true;
    jq.enable = true;
  };

  # user specific packages instead of system wide
  home.packages = with pkgs; [
    devenv_1_8_1
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

    kubectl
    kubectx
    kubernetes-helm
    minikube

    terraform
    tflint
    trivy

    rustup
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

    # kotlin
    # jdk21
    # gradle
    # ktlint
    # ktfmt

    # remember to disable ipv6, otherwise super slow gcloud
    # networksetup -setv6off Wi-Fi
    (google-cloud-sdk.withExtraComponents (
      with pkgs.google-cloud-sdk.components;
      [
        gke-gcloud-auth-plugin
        package-go-module
        pubsub-emulator
      ]
    ))
    google-cloud-sql-proxy

    # docker
    # docker-compose
    # dockerfile-language-server
    # docker-compose-language-service

    # protobuf
    # protolint
    # buf

    # LSP execs, formatter and linters for neovim
    yaml-language-server
    yamllint

    vim-language-server
    lua-language-server
    stylua

    #kotlin-language-server # TODO: migrate to kotlinLspWrapper
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
