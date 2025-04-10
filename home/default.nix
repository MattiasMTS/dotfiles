{ config, pkgs, lib, inputs, username, ... }:
let inherit (config.lib.file) mkOutOfStoreSymlink;
in {
  programs.home-manager.enable = true;
  home.stateVersion = "24.11";

  home.username = username;
  home.homeDirectory = "/Users/${username}";
  xdg.enable = true;

  # packages managed outside of home-manager
  xdg.configFile.nvim = {
    source = mkOutOfStoreSymlink
      "/Users/${username}/src/github.com/projects/dotfiles/.config/nvim";
    force = true;
  };
  xdg.configFile.ghostty.source = mkOutOfStoreSymlink
    "/Users/${username}/src/github.com/projects/dotfiles/.config/ghostty";
  xdg.configFile.sesh.source = mkOutOfStoreSymlink
    "/Users/${username}/src/github.com/projects/dotfiles/.config/sesh";

  # applications/programs
  programs = {
    neovim = {
      enable = true;
      package = inputs.neovim-nightly-overlay.packages.${pkgs.system}.default;
      withPython3 = true;
    };
    # FIXME: broken build on v1.0.1
    # ghostty = import ./programs/ghostty.nix { inherit pkgs; };
    zsh = import ./programs/zsh.nix { inherit config pkgs lib; };
    starship = import ./programs/starship.nix { inherit pkgs; };
    git = import ./programs/git.nix { inherit username lib; };
    tmux = import ./programs/tmux.nix { inherit pkgs; };
    fzf = import ./programs/fzf.nix { inherit pkgs lib; };
    zoxide = (import ./programs/zoxide.nix { inherit pkgs; });
    go = import ./programs/go.nix { inherit pkgs; };
    java = import ./programs/java.nix { inherit pkgs; };
    lazygit = import ./programs/lazygit.nix { inherit pkgs; };
    gh = import ./programs/gh.nix { inherit pkgs; };
    bat = { enable = true; }; # for syntax highlighting in fzf
    k9s = { enable = true; };
    ripgrep = { enable = true; };
    jq = { enable = true; };
    jujutsu = { enable = true; };
    ssh = import ./programs/ssh.nix { inherit pkgs; };
  };

  # user specific packages instead of system wide
  home.packages = with pkgs; [
    fzf
    fd
    delta
    sesh
    kubectl
    kubectx
    # stern
    # uv
    # duckdb
    terraform
    # terragrunt
    python310
    nodejs_23
    pnpm_9
    kubernetes-helm
    minikube

    kotlin
    jdk17
    gradle
    tree
    ruff
    # (google-cloud-sdk.withExtraComponents
    #       [ google-cloud-sdk.components.gke-gcloud-auth-plugin ])
    # google-cloud-sql-proxy
    # grpcurl
    presenterm
  ];

}
