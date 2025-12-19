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
    vim = "nvim";
  };

  environmentVariables = {
    GPG_TTY = "(tty)";
  };

  extraEnv = ''
    # Override nushell's open with system open (loaded in non-interactive mode)
    alias open = ^open
  '';

  extraConfig = ''
    # Sesh sessions function with fzf
    def sesh-sessions [] {
      let session = (sesh list | fzf --height 40% --reverse --border-label ' sesh ' --border --prompt '⚡  ')
      if ($session | is-not-empty) {
        sesh connect $session
      }
    }

    # Keybinding for Ctrl+F to trigger sesh-sessions
    $env.config = ($env.config | default {} | merge {
      keybindings: [
        {
          name: sesh_sessions
          modifier: control
          keycode: char_f
          mode: [emacs, vi_normal, vi_insert]
          event: { send: executehostcommand cmd: "sesh-sessions" }
        }
      ]
    })

    $env.config.buffer_editor = "vi"
    $env.config.show_banner = false
  '';
}
