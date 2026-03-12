{
  pkgs,
  lib,
  inputs,
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
    _1password-cli
    _1password-gui
  ];

  homebrew = {
    enable = true;
    casks = [
      "ghostty"
      "spotify"
      "brave-browser"
      "datagrip"
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
  determinateNix.customSettings = {
    eval-cores = 1;
    extra-experimental-features = [
      "build-time-fetch-tree" # Enables build-time flake inputs
      "parallel-eval" # Enables parallel evaluation
    ];
    extra-trusted-users = [
      username
    ];
    extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
    extra-substituters = "https://devenv.cachix.org";
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.iosevka
    maple-mono.NF
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
  };

  system.defaults.screencapture = {
    location = "~/Downloads";
    show-thumbnail = true;
  };

  system.activationScripts.postActivation.text = ''
    osascript -e 'tell application "System Events" to tell every desktop to set picture to "/System/Library/Desktop Pictures/Solid Colors/Black.png"'
  '';

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
  nixpkgs.overlays = import ../../overlays { inherit inputs; };

  # whitelist unfree packages
  nixpkgs.config.allowUnfree = true;
}
