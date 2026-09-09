# cmux session worktrees

Run an agent from the primary repository and let it use `wt switch` as usual.
After a successful switch, `cmux-session.py` associates the worktree with the
existing cmux workspace and agent surface:

- Workspace title (including Cmd-P): `lovable · ms/feature-name`.
- Directory label: the primary repository.
- Native branch, dirty status, and GitHub PR: the worktree.

This uses cmux 0.64.22's directory report with a separate display label. It
changes cmux's tracked directory, so new panes inherit the worktree. It does
not change the running agent's process directory. Native cmux tracking owns
PR discovery and refresh; the hook does not poll GitHub.

Switching to the primary worktree or removing the associated worktree restores
the repository directory and previous workspace title. Removing an older
worktree does not clear a newer association. A manual title set after binding
is preserved during cleanup. The helper does nothing outside cmux.

## Installation and existing sessions

Home Manager already links `~/.config/worktrunk` to this directory in the main
dotfiles checkout. Once these files are in that checkout, Worktrunk reads the
new hooks without restarting cmux or the agent. Python 3.9+ must be on PATH.

For an existing agent session, have that agent run `wt switch <its-branch>`.
To bind explicitly from its terminal, use:

```sh
python3 ~/.config/worktrunk/cmux-session.py bind /absolute/path/to/worktree
```

The workspace and surface come from the invoking terminal's cmux environment;
the currently focused workspace is never used as a substitute.

## Limits

This is a directory-report integration, not a native persistent Git override.
Later terminal directory reports (including a return to the shell prompt) can
replace the association's tracked directory; `wt switch` binds it again. The
feature title remains until switching or cleanup. Use one active worktree per
agent workspace; other panes retain their own directory tracking.

Bindings are stored under `$XDG_STATE_HOME/cmux/worktrunk-sessions` (default
`~/.local/state/cmux/worktrunk-sessions`). Detached Worktrunk hooks forward
cmux's inherited socket capability. If socket access fails, Git work still
completes and the hook logs a short error.

## Verification

```sh
PYTHONDONTWRITEBYTECODE=1 python3 -m unittest discover -s .config/worktrunk -p 'test_*.py' -v
wt --config .config/worktrunk/config.toml hook post-switch --dry-run
wt --config .config/worktrunk/config.toml hook post-remove --dry-run
```
