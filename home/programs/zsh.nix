{ config, pkgs, lib, ... }: {
  enable = true;
  history.size = 10000;
  history.path = "${config.xdg.dataHome}/zsh/history";
  enableCompletion = true;
  shellAliases = {
    vim = "nvim";
    lg = "lazygit";
    ls = "ls --color=auto";
    k = "kubectl";
    kc = "kubectx";
    kn = "kubens";
    z = "zoxide";
    nv = "cd ~/src/github.com/northvolt/";
    pj = "cd ~/src/github.com/projects/";
    dot = "cd ~/src/github.com/projects/dotfiles/";
    tksv = "tmux kill-server";
    tf = "terraform";
    tg = "terragrunt";
    cat = "bat";
    docker = "podman";
    docker-compose = "podman-compose";
  };
  sessionVariables = {
    EDITOR = "nvim";
    # go northvolt setup
    # to store the GOPROXY_PASS token in the macOS keychain run
    # security add-generic-password -a $USER -s GOPROXY_PASS -w
    GOPROXY =
      "https://nv:$(security find-generic-password -gs GOPROXY_PASS -w)@gomod.aut.aws.nvlt.co";
    GONOPROXY = "none";
  };
  initExtraFirst = ''
    # custom NV binaries
    path+="$HOME/go/bin"
    fpath+="$HOME/go/bin"
  '';
  initExtra = ''
    if [ -n "$TTY" ]; then
      export GPG_TTY=$(tty)
    else
      export GPG_TTY="$TTY"
    fi

    function awsso() {
      local profile
      # $(aws configure list-profiles --no-cli-auto-prompt | fzf)
      profile=$(awk '/\[profile/ {print $2 }' <~/.aws/config | tr -d "]" | fzf) 
      if [ -z "$profile" ]; then
        return
      fi
      aws --no-cli-auto-prompt --no-cli-pager sso login --profile="$profile"
      export AWS_PROFILE="$profile"
    }

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
    zle -N awsso
    bindkey '^f' sesh-sessions
    bindkey '^w' awsso
  '';
  envExtra = "\n";
  plugins = [
    {
      name = "zsh-autosuggestions";
      src = pkgs.zsh-autosuggestions;
      file = "share/zsh-autosuggestions/zsh-autosuggestions.zsh";
    }
    {
      name = "zsh-completions";
      src = pkgs.zsh-completions;
      file = "share/zsh-completions/zsh-completions.zsh";
    }
    {
      name = "zsh-syntax-highlighting";
      src = pkgs.zsh-syntax-highlighting;
      file = "share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh";
    }
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
