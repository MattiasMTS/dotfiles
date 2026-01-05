{ pkgs, ... }:
{
  enable = true;
  settings = {
    aliases = {
      co = "pr checkout";
      pv = "pr view";
      dependabot-prs = ''pr list --author "app/dependabot" --json number --jq ".[].number"'';
    };
    editor = "nvim";
    git_protocol = "ssh";
  };
}
