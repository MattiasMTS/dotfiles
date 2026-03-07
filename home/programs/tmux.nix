{ pkgs, dotfilesPath, ... }:
let
  terminal = "xterm-ghostty";
in
{
  programs.tmux = {
    enable = true;

    aggressiveResize = true;
    baseIndex = 1;
    escapeTime = 0;
    disableConfirmationPrompt = true;
    historyLimit = 100000;
    keyMode = "vi";
    shell = "${pkgs.zsh}/bin/zsh";
    shortcut = "a";
    terminal = terminal;
    newSession = false;
    secureSocket = false;
    sensibleOnTop = false;

    plugins = with pkgs.tmuxPlugins; [
      resurrect
      yank
      catppuccin
    ];
    extraConfig = ''
      set -g default-terminal "${terminal}"
      source-file ${dotfilesPath}/.config/tmux/tmux.extra.conf
    '';
  };
}
