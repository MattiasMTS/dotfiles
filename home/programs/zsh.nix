{ pkgs, username, ... }:
{
  enable = true;
  history.size = 10000;
  enableCompletion = true;
  syntaxHighlighting.enable = true;
  autosuggestion.enable = true;
  shellAliases = {
    # general misc
    lg = "lazygit";
    ld = "lazydocker";
    ls = "ls --color=auto";
    z = "zoxide";
    cat = "bat";
    tksv = "tmux kill-server";
    # kubernetes
    k = "kubectl";
    kc = "kubectx";
    # shortcuts to projects
    le = "cd ~/src/github.com/lovable/";
    pj = "cd ~/src/github.com/projects/";
    tf = "tofu";
    ch = "clickhouse-cli";
  };
  # TODO: check how to make this work with sessionVariables
  initContent = ''
    export PATH=$PATH:/Users/${username}/go/bin

    if [ -n "$TTY" ]; then
      export GPG_TTY=$(tty)
    else
      export GPG_TTY="$TTY"
    fi

    function sesh-sessions() {
      {
        exec </dev/tty
        exec <&1
        local session
        session=$(sesh list | fzf --height 40% --reverse \
          --border-label ' sesh ' \
          --border --prompt '⚡  '
          )
        # zle reset-prompt > /dev/null 3>&1 || true
        [[ -z "$session" ]] && return
        sesh connect $session
      }
    }

    # keymaps
    zle -N sesh-sessions
    bindkey '^f' sesh-sessions
  '';
  plugins = [
    {
      name = "fzf-tab";
      src = pkgs.zsh-fzf-tab;
      file = "share/fzf-tab/fzf-tab.plugin.zsh";
    }
    {
      name = "vi-mode";
      src = pkgs.zsh-vi-mode;
      file = "share/zsh-vi-mode/zsh-vi-mode.plugin.zsh";
    }
  ];
}
