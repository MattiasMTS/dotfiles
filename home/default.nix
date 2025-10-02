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

  copilot-cli = pkgs.buildNpmPackage {
    pname = "copilot-cli";
    version = "0.0.331";
    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@github/copilot/-/copilot-0.0.331.tgz";
      sha256 = "sha256-+UxS3YeHuiNKa3TSGNpEKrvD7o7rmfEYoesUirluxFA=";
    };
    npmDepsHash = "sha256-towDD5nkPkju1ZbE0xgybM02tuM/5NuFAu1zdZFSlJ4=";
    # requires a lock file... get this manually by fetching the tar and
    # running npm install --package-lock-only
    postPatch = ''
      cp  ${./../copilot/package-lock.json} ./package-lock.json
    '';
    dontNpmBuild = true;
  };

  # mcphub = inputs.mcp-hub.packages."${pkgs.system}".default;
  nvim-nightly = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
in
{
  programs.home-manager.enable = true;
  home.stateVersion = "25.11";

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
    zsh = import ./programs/zsh.nix { inherit config pkgs lib; };
    starship = import ./programs/starship.nix { inherit pkgs; };
    git = import ./programs/git.nix { inherit username lib; };
    tmux = import ./programs/tmux.nix { inherit pkgs; };
    fzf = import ./programs/fzf.nix { inherit pkgs lib; };
    direnv = import ./programs/direnv.nix { inherit pkgs lib; };
    zoxide = (import ./programs/zoxide.nix { inherit pkgs; });
    go = import ./programs/go.nix { inherit pkgs username; };
    java = import ./programs/java.nix { inherit pkgs; };
    lazygit = import ./programs/lazygit.nix { inherit pkgs; };
    lazydocker = import ./programs/lazydocker.nix { inherit pkgs; };
    gh = import ./programs/gh.nix { inherit pkgs; };
    ssh = import ./programs/ssh.nix { inherit pkgs; };
    bat.enable = true;
    k9s.enable = true;
    ripgrep.enable = true;
    jq.enable = true;
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
    presenterm

    kubectl
    kubectx
    kubernetes-helm
    minikube
    stern

    terraform
    tflint
    trivy
    atlas

    rustup

    python313
    python313Packages.ipython
    python313Packages.sqlfmt
    # vectorcode # used in codecompanion
    # mcphub # used in codecompanion

    # pnpm_9
    nodejs_24
    bun
    vtsls
    deno
    nodePackages.prettier
    nodePackages.vscode-json-languageserver

    duckdb
    uv
    ruff
    pre-commit

    kotlin
    jdk21
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
    google-cloud-sql-proxy

    docker
    docker-compose
    dockerfile-language-server
    docker-compose-language-service

    protobuf
    protolint
    buf
    tree-sitter

    # LSP execs, formatter and linters for neovim
    yaml-language-server
    yamllint

    vim-language-server
    lua-language-server
    stylua

    kotlin-language-server # TODO: migrate to kotlinLspWrapper
    bash-language-server

    # pyright
    basedpyright

    gopls
    templ
    superhtml
    golines
    gofumpt
    copilot-language-server

    terraform-ls
    nil
    helm-ls
    markdown-oxide # trying this out

    steampipe
    temporal-cli
    copilot-cli
  ];
}
