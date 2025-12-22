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
        $env.config.use_kitty_protocol = true
        $env.config.completions = {
          algorithm: fuzzy
          quick: false
          partial: true
        }
        $env.config.keybindings ++= [
      {
        name: completion_menu
        modifier: alt
        keycode: tab
        mode: emacs
        event: { send: menu name: ide_completion_menu }
      }
      {
        name: insert_fzf_result
        modifier: alt
        keycode: char_/
        mode: [emacs vi_normal vi_insert]
        event: {
          send: executehostcommand
          cmd: "fzf,path"
        }
      }
      {
        name: comark_fzf_smart
        modifier: alt
        keycode: "char_,"
        mode: [emacs vi_insert vi_normal]
        event: {
          send: executehostcommand
          cmd: "fzf,smart"
        }
      }
    ]
  '';
}
