{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  dotDir = "${config.xdg.configHome}/zsh";
  zcompdump = "${dotDir}/.zcompdump";
in
{
  programs.zsh = {
    enable = true;
    inherit dotDir;
    envExtra = lib.optionalString pkgs.stdenv.hostPlatform.isDarwin ''
      export CC=${lib.escapeShellArg config.home.sessionVariables.CC}
      export CXX=${lib.escapeShellArg config.home.sessionVariables.CXX}
    '';
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
      ws = "wt switch ";
      wsc = "wt switch -c ";
      wr = "wt remove ";
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

      # Enable 1Password CLI biometric unlock via desktop app
      export OP_BIOMETRIC_UNLOCK_ENABLED=true

      # Grafana MCP service account token (static, cached to file)
      _grafana_token_cache="$HOME/.cache/grafana-mcp-token"
      if [ ! -f "$_grafana_token_cache" ]; then
        mkdir -p "$(dirname "$_grafana_token_cache")"
        op read "op://Shared/grafana-mcp-sa/credential" 2>/dev/null > "$_grafana_token_cache"
      fi
      export GRAFANA_SERVICE_ACCOUNT_TOKEN=$(cat "$_grafana_token_cache")

      eval "$(wt config shell init zsh)"

      # Auto-rename cmux workspace/tab to short path on cd
      if [[ -n "$CMUX_WORKSPACE_ID" ]]; then
        _cmux_rename() {
          local short="''${(%):-%1~}"
          cmux rename-workspace "$short" &>/dev/null
        }
        autoload -Uz add-zsh-hook
        add-zsh-hook chpwd _cmux_rename
        _cmux_rename  # rename on shell start too
      fi
    '';
    plugins = [
      {
        name = "fzf-tab";
        src = pkgs.zsh-fzf-tab;
        file = "share/fzf-tab/fzf-tab.plugin.zsh";
      }
    ];
  };
}
