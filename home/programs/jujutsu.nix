{ username, ... }:
{
  enable = true;

  settings = {
    user = {
      name = "Mattias Sjödin";
      email = "mattias.sjodin.6764@hotmail.com";
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
      default-command = [
        "log"
        "--no-pager"
      ];
    };

    aliases = {
      # Common shortcuts
      st = [ "status" ];
      l = [ "log" ];
      d = [ "diff" ];
    };

    # Revset aliases
    revset-aliases = {
      "mine()" = "author(exact:'mattias.sjodin.6764@hotmail.com')";
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
}
