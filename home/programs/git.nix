{ username, ... }:
{
  enable = true;
  userName = "MattiasMTS";
  userEmail = "mattias.sjodin.6764@hotmail.com";

  signing = {
    key = "/Users/${username}/.ssh/id_ed25519.pub";
    signByDefault = true;
    format = "ssh";
  };

  extraConfig = {
    interactive.diffFilter = "delta --color-only";
    delta.navigate = true;
    merge.conflictstyle = "diff3";
    diff.colorMoved = "default";
    init.defaultBranch = "main";
    color.ui = true;
    branch.autosetuprebase = "always";
    rebase.autoStash = true;
    pull.rebase = true;

    fetch = {
      prune = true;
      pruneTags = true;
      all = true;
    };

    "includeIf \"gitdir:~/epidemicsound/\"" = {
      email = "mattias.sjodin@epidemicsound.com";
    };
  };

  aliases = {
    standup = ''
      !git log --since yesterday --author="$(git config user.name)\|$(git config user.email)" \
          --all -i \
          --format="%C(yellow)%h%Creset|%C(bold blue)%s%Creset|%C(green)%ad%Creset|%C(cyan)%ar%Creset|%C(magenta)%(trailers:key=Resolves,separator=\ )%Creset|-" \
          --shortstat --date=format:"%Y-%m-%d" | \
          grep -v "^$" | paste -d"|" - - | \
          sed -E "s/([0-9]+) files? changed/\x1b[36m\1 files\x1b[0m/g; \
                  s/([0-9]+) insertions?\(\+\)/\x1b[32m\1+\x1b[0m/g; \
                  s/([0-9]+) deletions?\(-\)/\x1b[31m\1-\x1b[0m/g" | \
          column -t -s'|' '';

    sprint = ''
      !git log --since="14 days ago" --author="$(git config user.name)\|$(git config user.email)" \
          --all -i \
          --format="%C(yellow)%h%Creset|%C(bold blue)%s%Creset|%C(green)%ad%Creset|%C(cyan)%ar%Creset|%C(magenta)%(trailers:key=Resolves,separator=\ )%Creset|-" \
          --shortstat --date=format:"%Y-%m-%d" | \
          grep -v "^$" | paste -d"|" - - | \
          sed -E "s/([0-9]+) files? changed/\x1b[36m\1 files\x1b[0m/g; \
                  s/([0-9]+) insertions?\(\+\)/\x1b[32m\1+\x1b[0m/g; \
                  s/([0-9]+) deletions?\(-\)/\x1b[31m\1-\x1b[0m/g" | \
          column -t -s'|' '';

    hotspots = ''
      !git log --since '7 days ago' \
          --author="$(git config user.name)\|$(git config user.email)" \
          --all -i --pretty=format: --name-only | \
          sort | uniq -c | sort -rn | head -10'';
  };
}
