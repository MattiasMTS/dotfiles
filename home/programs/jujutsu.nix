{ config, username, ... }:
{
  programs.jujutsu = {
    enable = true;

    settings = {
      user = {
        name = "Mattias Sjödin";
        email = config.programs.git.settings.user.email;
      };

      # SSH signing configuration
      signing = {
        behavior = "own";
        backend = "ssh";
        key = "/Users/${username}/.ssh/id_ed25519.pub";
      };

      # Git interoperability
      git = {
        auto-local-branch = true;
        abandon-unreachable-commits = true;
      };

      # UI configuration - use delta for diffs
      ui = {
        default-command = "status";
        merge-editor = "nvim";
        paginate = "auto";
      };

      aliases = {
        # Common shortcuts
        st = [ "status" ];
        l = [ "log" ];
        d = [ "diff" ];
      };

      # Conditional configuration for work repositories
      "--scope" = [
        {
          when = {
            repositories = [ "~/lovablelabs" ];
          };
          user = {
            email = "msjodin@lovable.dev";
          };
        }
      ];
    };

  };
}
