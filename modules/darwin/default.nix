{
  pkgs,
  lib,
  username,
  ...
}:
{

  # yes it's I
  users.users.${username} = {
    name = username;
    home = "/Users/${username}";
    isHidden = false;
    shell = pkgs.zsh;
  };

  # system wide packages (all users)
  environment.systemPackages = with pkgs; [
    brave
    raycast
    neovim
    git
    tmux
    gnumake
  ];

  homebrew = {
    enable = true;
    casks = [
      "ghostty"
      "spotify"
      # "orbstack"
    ];
    brews = [ ];
    taps = [ ];
  };

  # enable flakes globally
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    keep-outputs = true
    keep-derivations = true
  '';
  # managed by determinate
  nix.enable = false;

  # ingest to custom conf.nix
  determinate-nix.customSettings = {
    eval-cores = 1;
    extra-experimental-features = [
      "build-time-fetch-tree" # Enables build-time flake inputs
      "parallel-eval" # Enables parallel evaluation
      "external-builders" # Enables linux-builder
    ];
    external-builders = ''[{"systems":["aarch64-linux","x86_64-linux"],"program":"/usr/local/bin/determinate-nixd","args":["builder"]}]'';
    extra-trusted-users = [
      username
    ];
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    maple-mono.NF
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
  };

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";

  # TODO: use overlays instead
  # whitelist unfree packages
  nixpkgs.config.allowUnfreePredicate =
    pkg:
    builtins.elem (lib.getName pkg) [
      "terraform"
      "raycast"
      "copilot-language-server"
      "claude-code"
    ];
}
