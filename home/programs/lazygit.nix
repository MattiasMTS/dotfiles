{ pkgs, ... }:
{
  enable = true;
  # enableZshIntegration = true;
  enableNushellIntegration = true;

  settings = {
    notARepository = "quit";
    gui = {
      showBottomLine = true;
      border = "rounded";
      nerdFontsVersion = 3;
      skipDiscardChangeWarning = false;
      skipStashWarning = false;
      mainPanelSplitMode = "flexible";
      commitLength.show = true;
      splitDiff = "auto";
      commandLogSize = 6;
      sidePanelWidth = 0.25;
    };
    os.editPreset = "nvim-remote";
    git.overrideGpg = true;
    git.pager = {
      colorArg = "always";
      pager = "difft --color always";
      useConfig = false;
    };

    customCommands = [
      # Create worktree from local branches (prompts for new branch name)
      {
        key = "W";
        context = "localBranches";
        description = "Create worktree with tmux session";
        prompts = [
          {
            type = "input";
            title = "Branch name for worktree";
            key = "BranchName";
          }
        ];
        command = "git-worktree-session add {{.Form.BranchName}}";
        loadingText = "Creating worktree...";
      }
      # Create worktree from remote branches (uses remote branch name)
      {
        key = "W";
        context = "remoteBranches";
        description = "Create worktree from remote branch";
        command = "git-worktree-session add {{.SelectedRemoteBranch.Name}}";
        loadingText = "Creating worktree...";
      }
      # Remove worktree and kill tmux session
      {
        key = "D";
        context = "worktrees";
        description = "Remove worktree and tmux session";
        prompts = [
          {
            type = "confirm";
            title = "Remove worktree and kill tmux session?";
          }
        ];
        command = "git-worktree-session remove {{.SelectedWorktree.Branch}}";
        loadingText = "Removing worktree...";
      }
    ];
  };

}
