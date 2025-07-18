{ pkgs, ... }:
let
  terminal = "xterm-256color";
in
{
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
  newSession = true;
  secureSocket = false;
  sensibleOnTop = false; # bug with starship/shell stuff..

  plugins = with pkgs.tmuxPlugins; [
    {
      plugin = resurrect;
      extraConfig = ''
        set -g @resurrect-capture-pane-contents 'on'
        set -g @resurrect-strategy-nvim 'session'
      '';
    }
    {
      plugin = yank;
      extraConfig = ''
        set -g @yank_action 'copy-pipe' # instead of copy-pipe-cancel, to not jump to bottom
      '';
    }
    {
      plugin = catppuccin;
      extraConfig = ''
        set -g @catppuccin_flavor "macchiato"
        set -g @catppuccin_window_status_style "rounded"

        set -g status-right-length 100
        set -g status-left-length 100
        set -g status-left ""
        set -g status-right "#{E:@catppuccin_status_application}"
        set -ag status-right "#{E:@catppuccin_status_session}"
        set -ag status-right "#{E:@catppuccin_status_uptime}"
      '';
    }
  ];
  extraConfig = ''
    # Undercurl
    set -g default-terminal "${terminal}"
    set -as terminal-overrides ',*:Smulx=\E[4::%p1%dm'  # undercurl support
    set -as terminal-overrides ',*:Setulc=\E[58::2::%p1%{65536}%/%d::%p1%{256}%/%{255}%&%d::%p1%{255}%&%d%;m'

    # kitty graphics protocol (for image in neovim)
    set -gq allow-passthrough on
    set -g visual-activity off

    # use system clipboard
    set -g set-clipboard on

    # lord forgive me
    set -g mouse on
    unbind -T copy-mode-vi MouseDragEnd1Pane

    # Window activity notificationf
    set -g monitor-activity on

    # keybindings
    bind-key -T copy-mode-vi 'v' send-keys -X begin-selection
    bind-key -T copy-mode-vi 'y' send-keys -X copy-selection-and-cancel
    bind-key -T copy-mode-vi 'C-v' send-keys -X rectangle-toggle

    # Smart pane switching with awareness of Neovim splits.
    bind-key -n C-h if -F "#{@pane-is-vim}" 'send-keys C-h'  'select-pane -L'
    bind-key -n C-j if -F "#{@pane-is-vim}" 'send-keys C-j'  'select-pane -D'
    bind-key -n C-k if -F "#{@pane-is-vim}" 'send-keys C-k'  'select-pane -U'
    bind-key -n C-l if -F "#{@pane-is-vim}" 'send-keys C-l'  'select-pane -R'

    # Smart pane resizing with awareness of Neovim splits.
    bind-key -n M-h if -F "#{@pane-is-vim}" 'send-keys M-h' 'resize-pane -L 3'
    bind-key -n M-j if -F "#{@pane-is-vim}" 'send-keys M-j' 'resize-pane -D 3'
    bind-key -n M-k if -F "#{@pane-is-vim}" 'send-keys M-k' 'resize-pane -U 3'
    bind-key -n M-l if -F "#{@pane-is-vim}" 'send-keys M-l' 'resize-pane -R 3'

    tmux_version='$(tmux -V | sed -En "s/^tmux ([0-9]+(.[0-9]+)?).*/\1/p")'
    if-shell -b '[ "$(echo "$tmux_version >= 3.0" | bc)" = 1 ]' \
        "bind-key -n 'C-\\' if -F \"#{@pane-is-vim}\" 'send-keys C-\\\\'  'select-pane -l'"

    bind-key -T copy-mode-vi 'C-h' select-pane -L
    bind-key -T copy-mode-vi 'C-j' select-pane -D
    bind-key -T copy-mode-vi 'C-k' select-pane -U
    bind-key -T copy-mode-vi 'C-l' select-pane -R
    bind-key -T copy-mode-vi 'C-\' select-pane -l

    # tmux sessionizer
    bind-key "f" run-shell "sesh connect \"$(
      sesh list --icons | fzf-tmux -p 80%,70% \
        --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
        --header '  ^a all ^t tmux ^g configs ^x zoxide ^d tmux kill ^f find' \
        --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons)' \
        --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
        --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
        --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
        --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~)' \
        --bind 'ctrl-d:execute(tmux kill-session -t {2..})+change-prompt(⚡  )+reload(sesh list --icons)' \
        --preview-window 'right:55%' \
        --preview 'sesh preview {}'
    )\""

  '';
}
