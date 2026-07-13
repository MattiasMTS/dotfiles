{
  pkgs,
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
  ];

  homebrew = {
    enable = true;
    casks = [
      "ghostty"
      "spotify"
      "brave-browser"
      "datagrip"
      "1password"
      "cmux"
    ];
    brews = [
      "dagu"
    ];
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

  determinateNix.determinateNixd.authentication.additionalNetrcSources = [
    "/etc/determinate/github-nix.netrc"
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true;

  # works around darwin-manual-html failing on nixos-render-docs' --toc-depth
  # -> --sidebar-depth rename (nixpkgs unstable ahead of nix-darwin master),
  # and speeds up rebuilds
  documentation.enable = false;
  # darwin-uninstaller evals its own default darwin system (docs enabled),
  # which hits the same --toc-depth failure; still available via
  # `nix run nix-darwin#darwin-uninstaller` if ever needed
  system.tools.darwin-uninstaller.enable = false;

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.iosevka
    nerd-fonts.departure-mono
    maple-mono.NF
  ];

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_18;
  };

  services.tailscale = {
    enable = false; # managed globally
    package = pkgs.tailscale;
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
  nixpkgs.overlays = import ../../overlays { };

  # whitelist unfree packages
  nixpkgs.config.allowUnfree = true;
}
