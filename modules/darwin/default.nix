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
    ];
    brews = [ ];
    taps = [ ];
  };

  # enable flakes globally
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];
  nix.optimise.automatic = true;
  # Auto upgrade nix package and the daemon service.
  nix.enable = true;

  # extra host specs
  # https://github.com/nix-darwin/nix-darwin/issues/1035
  # networking.extraHosts = ''
  #   127.0.0.1	  kubernetes.docker.internal
  #   127.0.0.1   kubernetes.default.svc.cluster.local
  # '';

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
      "obsidian"
      "copilot-language-server"
    ];

  # do garbage collection bi-daily to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 2d";
  };
}
