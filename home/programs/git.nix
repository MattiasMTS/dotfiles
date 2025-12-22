{ username, ... }:
{
  enable = true;

  signing = {
    key = "/Users/${username}/.ssh/id_ed25519.pub";
    signByDefault = true;
    format = "ssh";
  };

  lfs.enable = true;

  settings = {
    user = {
      name = "MattiasMTS";
      email = "mattias.sjodin.6764@hotmail.com";
    };

    # difftastic configuration
    diff = {
      tool = "difft";
      colorMoved = "default";
    };
    difftool = {
      prompt = false;
      difftastic.cmd = ''difft "$LOCAL" "$REMOTE"'';
    };
    pager.difftool = true;
    interactive.diffFilter = "delta --color-only";
    delta.navigate = true;

    merge.conflictstyle = "diff3";
    init.defaultBranch = "main";
    color.ui = true;
    branch.autosetuprebase = "always";
    rebase = {
      autoStash = true;
      updateRefs = true; # to make stacked branches work nicely
    };
    pull.rebase = true;

    fetch = {
      prune = true;
      pruneTags = true;
      all = true;
    };

    "includeIf \"gitdir:~/lovablelabs/\"" = {
      email = "msjodin@lovable.dev";
    };

    alias = {
      # Compact standup: grouped commits, summary stats at end
      standup = "!f() { echo '📋 Since yesterday:'; git log --since=yesterday --author=\"$(git config user.name)\" --all --format='  %h %s' --no-merges 2>/dev/null | head -30; echo ''; echo '📊 Stats:'; git diff --shortstat \"$(git log --since=yesterday --author=\"$(git config user.name)\" --all --format='%H' --no-merges | tail -1)^\" HEAD 2>/dev/null || echo '  No changes'; }; f";
      # Weekly: grouped by date for readability
      weekly = "!f() { echo '📋 This week:'; git log --since='1 week ago' --author=\"$(git config user.name)\" --all --format='%ad  %h %s' --date=format:'%a %d' --no-merges --reverse 2>/dev/null | head -50; echo ''; echo '📊 Stats:'; git diff --shortstat \"$(git log --since='1 week ago' --author=\"$(git config user.name)\" --all --format='%H' --no-merges | tail -1)^\" HEAD 2>/dev/null || echo '  No changes'; }; f";
      standup-summary = "!git standup | claude -p 'Summarize this git activity for a standup. Be concise, use bullet points.'";
      weekly-summary = "!git weekly | claude -p 'Summarize this week of git activity. Group by theme/feature. Be concise.'";
    };
  };
}
