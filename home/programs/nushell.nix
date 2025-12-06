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
  };

  environmentVariables = {
    GPG_TTY = "(tty)";
  };

  extraConfig = ''
    # Add Go bin to PATH
    $env.PATH = ($env.PATH | split row (char esep) | prepend $"/Users/${username}/go/bin")

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
  '';
}
