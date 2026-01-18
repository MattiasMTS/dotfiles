{
  pkgs,
  username,
  ...
}:
let
  dotDir = ".config/zsh";
  zcompdump = "/Users/${username}/${dotDir}/.zcompdump";
in
{
  enable = true;
  inherit dotDir;
  history.size = 10000;
  enableCompletion = true;
  # Cache completions - only regenerate dump once per day
  completionInit = ''
    autoload -Uz compinit
    if [[ -n ${zcompdump}(#qN.mh+24) ]]; then
      compinit -d "${zcompdump}"
    else
      compinit -C -d "${zcompdump}"
    fi
  '';
  syntaxHighlighting.enable = true;
  autosuggestion.enable = true;
  defaultKeymap = "viins"; # vi-mode
  shellAliases = {
    lg = "lazygit";
    ld = "lazydocker";
    z = "zoxide";
    ls = "ls --color=auto";
    cat = "bat";
    tksv = "tmux kill-server";
    k = "kubectl";
    kc = "kubectx";
    tf = "tofu";
    vim = "nvim";
  };
  initContent = ''
    export PATH=$PATH:/Users/${username}/go/bin

    if [ -n "$TTY" ]; then
      export GPG_TTY=$(tty)
    else
      export GPG_TTY="$TTY"
    fi

    # Vi mode settings
    export KEYTIMEOUT=1  # Reduce escape delay
    export ZSH_AUTOSUGGEST_USE_ASYNC=1
  '';
  plugins = [
    {
      name = "fzf-tab";
      src = pkgs.zsh-fzf-tab;
      file = "share/fzf-tab/fzf-tab.plugin.zsh";
    }
  ];
}
