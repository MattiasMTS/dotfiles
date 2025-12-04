{ pkgs }:

pkgs.writeShellScriptBin "git-worktree-session" ''
  set -euo pipefail

  cmd="''${1:-}"
  branch="''${2:-}"

  # Strip origin/ prefix from remote branch names
  branch="''${branch#origin/}"

  if [ -z "$cmd" ]; then
    echo "Usage: git-worktree-session <add|remove|cleanup> [branch-name]"
    exit 1
  fi

  repo_root=$(${pkgs.git}/bin/git rev-parse --show-toplevel)
  repo_name=$(basename "$repo_root")
  parent_dir=$(dirname "$repo_root")

  case "$cmd" in
    add)
      if [ -z "$branch" ]; then
        echo "Error: branch name required for 'add' command"
        exit 1
      fi

      worktree_path="''${parent_dir}/''${repo_name}-''${branch}"
      session_name="''${repo_name}-''${branch}"

      # create worktree
      if ${pkgs.git}/bin/git show-ref --verify --quiet "refs/heads/''${branch}" 2>/dev/null; then
        echo "Checking out existing branch: $branch"
        ${pkgs.git}/bin/git worktree add "$worktree_path" "$branch"
      elif ${pkgs.git}/bin/git show-ref --verify --quiet "refs/remotes/origin/''${branch}" 2>/dev/null; then
        echo "Checking out remote branch: origin/$branch"
        ${pkgs.git}/bin/git worktree add "$worktree_path" "$branch"
      else
        echo "Creating new branch: $branch"
        ${pkgs.git}/bin/git worktree add -b "$branch" "$worktree_path"
      fi

      # create tmux session (if it doesn't exist)
      if ! ${pkgs.tmux}/bin/tmux has-session -t "$session_name" 2>/dev/null; then
        ${pkgs.tmux}/bin/tmux new-session -d -s "$session_name" -c "$worktree_path"
      fi

      ${pkgs.tmux}/bin/tmux switch-client -t "$session_name"
      ;;

    remove)
      if [ -z "$branch" ]; then
        echo "Error: branch name required for 'remove' command"
        exit 1
      fi

      worktree_path="''${parent_dir}/''${repo_name}-''${branch}"
      session_name="''${repo_name}-''${branch}"

      # if pruning on merge should be removed
      if [ "''${GIT_WORKTREE_NO_AUTO_CLEANUP:-}" = "1" ]; then
        echo "Auto-cleanup disabled via GIT_WORKTREE_NO_AUTO_CLEANUP"
        exit 0
      fi

      # kill tmux session if it exists
      if ${pkgs.tmux}/bin/tmux has-session -t "$session_name" 2>/dev/null; then
        ${pkgs.tmux}/bin/tmux kill-session -t "$session_name"
        echo "Killed tmux session: $session_name"
      fi

      # remove worktree if it exists
      if [ -d "$worktree_path" ]; then
        ${pkgs.git}/bin/git worktree remove "$worktree_path" --force
        echo "Removed worktree: $worktree_path"
      fi
      ;;

    cleanup)
      main_branch="main"

      # list of worktrees
      ${pkgs.git}/bin/git worktree list --porcelain | while read -r line; do
        if [[ "$line" == worktree* ]]; then
          wt_path="''${line#worktree }"

          # skip main worktree
          if [ "$wt_path" = "$repo_root" ]; then
            continue
          fi

          # get branch name for this worktree
          wt_branch=$(${pkgs.git}/bin/git -C "$wt_path" branch --show-current 2>/dev/null || true)

          if [ -n "$wt_branch" ]; then
            # Check if branch is merged to main
            if ${pkgs.git}/bin/git branch --merged "$main_branch" 2>/dev/null | grep -q "^\s*$wt_branch$"; then
              echo "Cleaning up merged worktree: $wt_path ($wt_branch)"
              session_name="''${repo_name}-''${wt_branch}"

              # Kill tmux session
              ${pkgs.tmux}/bin/tmux kill-session -t "$session_name" 2>/dev/null || true

              # Remove worktree
              ${pkgs.git}/bin/git worktree remove "$wt_path" --force 2>/dev/null || true
            fi
          fi
        fi
      done
      ;;

    list)
      ${pkgs.git}/bin/git worktree list
      ;;

    *)
      echo "Unknown command: $cmd"
      echo "Usage: git-worktree-session <add|remove|cleanup|list> [branch-name]"
      exit 1
      ;;
  esac
''
