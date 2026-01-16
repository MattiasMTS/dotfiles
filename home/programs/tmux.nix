{ pkgs, ... }:
let
  terminal = "xterm-ghostty";
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
        set -g @catppuccin_status_background "none"
        set -g @catppuccin_window_status_style "none"
        set -g @catppuccin_pane_status_enabled "off"
        set -g @catppuccin_pane_border_status "off"

        # status left look and feel
        set -g status-left-length 100
        set -g status-left ""
        set -ga status-left "#{?client_prefix,#{#[bg=#{@thm_red},fg=#{@thm_bg},bold]  #S },#{#[bg=#{@thm_bg},fg=#{@thm_green}]  #S }}"
        set -ga status-left "#[bg=#{@thm_bg},fg=#{@thm_overlay_0},none]│"
        set -ga status-left "#[bg=#{@thm_bg},fg=#{@thm_maroon}]  #{pane_current_command} "
        set -ga status-left "#[bg=#{@thm_bg},fg=#{@thm_overlay_0},none]│"
        # set -ga status-left "#[bg=#{@thm_bg},fg=#{@thm_blue}]  #{=/-32/...:#{s|$USER|~|:#{b:pane_current_path}}} "
        set -ga status-left "#[bg=#{@thm_bg},fg=#{@thm_overlay_0},none]#{?window_zoomed_flag,│,}"
        set -ga status-left "#[bg=#{@thm_bg},fg=#{@thm_yellow}]#{?window_zoomed_flag,  zoom ,}"

        # status right look and feel
        set -g status-right-length 100
        set -g status-right ""
        set -ga status-right "#[bg=#{@thm_bg},fg=#{@thm_overlay_0}, none]│"
        set -ga status-right "#[bg=#{@thm_bg},fg=#{@thm_overlay_0}, none]│"
        set -ga status-right "#[bg=#{@thm_bg},fg=#{@thm_blue}] 󰭦 %Y-%m-%d 󰅐 %H:%M "
      '';
    }
  ];
  extraConfig = ''
    # pane border look and feel
    # setw -g pane-border-status top
    # setw -g pane-border-format ""
    setw -g pane-active-border-style "bg=#{@thm_bg},fg=#{@thm_overlay_0}"
    setw -g pane-border-style "bg=#{@thm_bg},fg=#{@thm_surface_0}"
    setw -g pane-border-lines single

    # window look and feel
    set -wg automatic-rename on
    set -g automatic-rename-format "Window"
    set -g window-status-format " #I#{?#{!=:#{window_name},Window},: #W,} "
    set -g window-status-style "bg=#{@thm_bg},fg=#{@thm_rosewater}"
    set -g window-status-last-style "bg=#{@thm_bg},fg=#{@thm_peach}"
    set -g window-status-activity-style "bg=#{@thm_red},fg=#{@thm_bg}"
    set -g window-status-bell-style "bg=#{@thm_red},fg=#{@thm_bg},bold"
    set -gF window-status-separator "#[bg=#{@thm_bg},fg=#{@thm_overlay_0}]│"

    set -g window-status-current-format " #I#{?#{!=:#{window_name},Window},: #W,} "
    set -g window-status-current-style "bg=#{@thm_peach},fg=#{@thm_bg},bold"

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

    # Window activity notification
    set -g monitor-activity off

    # keybindings
    bind-key a last-window
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
    bind-key "f" run-shell "sesh-list connect \"$(
      sesh-list | fzf-tmux -p 80%,70% \
        --no-sort --ansi --border-label ' sesh ' --prompt '⚡  ' \
        --delimiter '\t' --with-nth 1 \
        --header '  ^t tmux ^x zoxide ^d kill session ^w worktree' \
        --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons)' \
        --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
        --bind 'ctrl-d:execute-silent(sesh-list delete {2})+reload(sesh-list)' \
        --bind 'ctrl-w:change-prompt(󰘬  )+reload(git-worktree-picker)' \
        --preview-window 'right:55%' \
        --preview 'sesh preview {2}' \
      | cut -f2
    )\""

  '';
}
