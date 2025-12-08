{ pkgs, username, ... }:
{
  enable = true;

  shellAliases = {
    lg = "lazygit";
    ld = "lazydocker";
    cat = "bat";
    tksv = "tmux kill-server";
    k = "kubectl";
    kc = "kubectx";
    tf = "tofu";
    nu-open = "open";
    open = "^open";
  };

  environmentVariables = {
    GPG_TTY = "(tty)";
  };

  extraConfig = ''
    # Sesh sessions function with fzf
    def sesh-sessions [] {
      let session = (sesh list | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
      if ($session | is-not-empty) {
        sesh connect $session
      }
    }

    $env.config.buffer_editor = "vi"
  '';
}
