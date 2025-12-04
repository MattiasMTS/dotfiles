{ pkgs, ... }:
{
  enable = true;

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
      # Delete branch with auto-cleanup of worktree
      {
        key = "d";
        context = "localBranches";
        description = "Delete branch (with worktree cleanup)";
        prompts = [
          {
            type = "confirm";
            title = "Delete branch '{{.SelectedLocalBranch.Name}}'?";
          }
        ];
        command = "git-worktree-session remove {{.SelectedLocalBranch.Name}} 2>/dev/null || true; git branch -d {{.SelectedLocalBranch.Name}}";
        loadingText = "Deleting branch...";
      }
      # Cleanup all merged worktrees
      {
        key = "C";
        context = "worktrees";
        description = "Cleanup merged worktrees";
        prompts = [
          {
            type = "confirm";
            title = "Cleanup all worktrees with merged branches?";
          }
        ];
        command = "git-worktree-session cleanup";
        loadingText = "Cleaning up...";
      }
    ];
  };

}
