{ pkgs, ... }:
{
  enable = true;
  settings.aliases = {
    co = "pr checkout";
    pv = "pr view";
    dependabot-prs = ''pr list --author "app/dependabot" --json number --jq ".[].number'';
  };
  settings.editor = "nvim";
  settings.git_protocol = "https";
}
