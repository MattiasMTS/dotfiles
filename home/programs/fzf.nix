{ pkgs, lib, ... }:
{
  enable = true;
  enableZshIntegration = true;
  tmux.enableShellIntegration = true;
  defaultOptions = [ "--bind=ctrl-j:down,ctrl-k:up" ];
  fileWidgetOptions = [
    "--preview '${lib.getExe pkgs.bat} --color=always --plain --line-range=:200 {}'"
  ];
  changeDirWidgetOptions = [ "--preview '${lib.getExe pkgs.tree}  -C {} | head -200'" ];
}
