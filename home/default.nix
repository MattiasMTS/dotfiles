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

  # Fetch and extract the Kotlin LSP zip file
  kotlinLsp =
    pkgs.runCommand "kotlin-lsp"
      {
        buildInputs = [ pkgs.unzip ];
      }
      ''
        mkdir -p $out/lib
        unzip ${
          pkgs.fetchurl {
            url = "https://download-cdn.jetbrains.com/kotlin-lsp/0.252.16998/kotlin-0.252.16998.zip";
            sha256 = "bWXvrTm0weirPqdmP/WSLySdsOWU0uBubx87MVvKoDc=";
          }
        } -d $out/lib
      '';

  # Create a wrapper script to run the Kotlin LSP
  kotlinLspWrapper = pkgs.writeShellScriptBin "kotlin-lsp" ''
    #!/usr/bin/env bash
    # Build the classpath with all .jar files in the lib directory
    CLASSPATH=$(find ${kotlinLsp}/lib -name "*.jar" | tr '\n' ':')
    exec java -cp "$CLASSPATH" com.intellij.internal.statistic.uploader.EventLogUploader "$@"
  '';
in
{
  programs.home-manager.enable = true;
  home.stateVersion = "25.11";

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  xdg.enable = true;

  # packages managed outside of home-manager
  xdg.configFile.nvim = {
    source = mkOutOfStoreSymlink "/Users/${username}/src/github.com/projects/dotfiles/.config/nvim";
    force = true;
  };
  xdg.configFile.ghostty.source = mkOutOfStoreSymlink "/Users/${username}/src/github.com/projects/dotfiles/.config/ghostty";
  xdg.configFile.sesh.source = mkOutOfStoreSymlink "/Users/${username}/src/github.com/projects/dotfiles/.config/sesh";

  # applications/programs
  programs = {
    neovim = {
      enable = true;
      package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
      defaultEditor = true;

      withPython3 = true;
      withNodeJs = true;

      vimdiffAlias = true;
      vimAlias = true;
    };
    zsh = import ./programs/zsh.nix { inherit config pkgs lib; };
    starship = import ./programs/starship.nix { inherit pkgs; };
    git = import ./programs/git.nix { inherit username lib; };
    tmux = import ./programs/tmux.nix { inherit pkgs; };
    fzf = import ./programs/fzf.nix { inherit pkgs lib; };
    zoxide = (import ./programs/zoxide.nix { inherit pkgs; });
    go = import ./programs/go.nix { inherit pkgs; };
    java = import ./programs/java.nix { inherit pkgs; };
    lazygit = import ./programs/lazygit.nix { inherit pkgs; };
    lazydocker = import ./programs/lazydocker.nix { inherit pkgs; };
    gh = import ./programs/gh.nix { inherit pkgs; };
    bat = {
      enable = true;
    }; # for syntax highlighting in fzf
    k9s = {
      enable = true;
    };
    ripgrep = {
      enable = true;
    };
    jq = {
      enable = true;
    };
    ssh = import ./programs/ssh.nix { inherit pkgs; };
  };

  # user specific packages instead of system wide
  home.packages = with pkgs; [
    fzf
    fd
    delta
    sesh
    obsidian
    tree
    nixfmt-rfc-style
    # presenterm

    kubectl
    kubectx
    # minikube

    terraform
    tflint
    tfsec

    python313
    python313Packages.ipython

    # pnpm_9
    nodejs_24
    nodePackages.prettier
    nodePackages.vscode-json-languageserver

    duckdb
    uv
    ruff
    pre-commit
    copier

    kotlin
    jdk17
    gradle
    ktlint
    ktfmt

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

    docker
    docker-compose

    protobuf
    protolint
    buf
    cargo

    # LSP execs, formatter and linters for neovim
    yaml-language-server
    vim-language-server
    lua-language-server
    # kotlin-language-server
    # kotlinLspWrapper
    bash-language-server
    dockerfile-language-server-nodejs
    docker-compose-language-service
    pyright
    gopls
    terraform-ls
    nil
    helm-ls
    gofumpt
    stylua
    yamllint

    kotlinLspWrapper
  ];
}
