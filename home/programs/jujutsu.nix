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
        "--limit"
        "7"
      ];
      diff-formatter = [
        "delta"
        "--color-only"
      ];
      pager = "delta";
    };

    # Aliases similar to your git setup
    aliases = {
      # Daily standup
      standup = [
        "log"
        "-r"
        "mine() & after(yesterday)"
        "--no-graph"
      ];

      # Sprint view (last 14 days)
      sprint = [
        "log"
        "-r"
        "mine() & after('14 days ago')"
        "--no-graph"
      ];

      # Hotspots - frequently modified files (approximation)
      hotspots = [
        "log"
        "-r"
        "mine() & after('7 days ago')"
        "--summary"
      ];

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
