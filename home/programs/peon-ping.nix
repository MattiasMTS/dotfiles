{
  pkgs,
  inputs,
  lib,
  ...
}:
{
  programs.peon-ping = {
    enable = true;
    package = inputs.peon-ping.packages.${pkgs.system}.peon-ping;
    settings = {
      default_pack = "peon";
      volume = 0.5;
      enabled = true;
      desktop_notifications = true;
      notification_style = "standard"; # see zsh.nix
      # overlay_theme = "jarvis";
      # https://github.com/PeonPing/peon-ping?tab=readme-ov-file#what-youll-hear
      categories = {
        "session.start" = true;
        "task.acknowledge" = true;
        "task.complete" = true;
        "task.error" = true;
        "input.required" = true;
        "resource.limit" = true;
        "user.spam" = true;
      };
      annoyed_threshold = 3;
      annoyed_window_seconds = 10;
      use_sound_effects_device = true;
    };

    installPacks = [ "peon" ];
    enableZshIntegration = true;
  };
}
