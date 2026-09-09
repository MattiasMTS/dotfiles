#!/usr/bin/env python3
"""Associate an existing cmux agent workspace with its Worktrunk worktree.

Uses cmux 0.64.22's report_pwd <label> --path=<directory> interface.
The tracked directory also becomes the default for new panes. An actual
terminal directory change can supersede it; `wt switch` binds it again.
No background polling: cmux owns Git status and GitHub PR refreshes.
"""

import contextlib
import fcntl
import json
import os
from pathlib import Path
import socket
import subprocess
import sys
import uuid


def command(*args):
    return subprocess.check_output(args, text=True, stderr=subprocess.PIPE, timeout=5).strip()


def cmux(*args):
    return command(os.environ.get("CMUX_BUNDLED_CLI_PATH") or "cmux", *args)


def quote(value):
    if any(ord(c) < 32 or ord(c) == 127 for c in value):
        raise ValueError("control characters in cmux metadata")
    return '"' + value.replace("\\", "\\\\").replace('"', '\\"') + '"'


def report_directory(workspace, surface, directory, label=None):
    payload = "report_pwd " + quote(label or directory)
    if label:
        payload += " --path=" + quote(directory)
    payload += f" --tab={workspace} --panel={surface}"
    capability = os.environ.get("CMUX_SOCKET_CAPABILITY", "")
    if capability:
        if any(c.isspace() for c in capability):
            raise ValueError("invalid cmux socket capability")
        # cmux's own shell integration uses this envelope so detached hooks
        # remain authorized even after their process ancestry changes.
        payload = f"_cmux_capability_v1 {capability} {payload}"
    with socket.socket(socket.AF_UNIX) as connection:
        connection.settimeout(3)
        connection.connect(os.environ["CMUX_SOCKET_PATH"])
        connection.sendall((payload + "\n").encode())
        response = bytearray()
        while b"\n" not in response and len(response) < 65536:
            chunk = connection.recv(4096)
            if not chunk:
                break
            response.extend(chunk)
    if not response.startswith(b"OK"):
        raise RuntimeError("cmux rejected the directory report")


def workspace_info(workspace):
    # Removal can be invoked from a different window than the owning session.
    windows = json.loads(cmux("rpc", "window.list", "{}"))["windows"]
    for window in windows:
        rows = json.loads(cmux("rpc", "workspace.list", json.dumps({
            "window_id": window["id"],
        })))["workspaces"]
        for row in rows:
            if row["id"].lower() == workspace.lower():
                return row
    return None


def state_root():
    root = Path(os.environ.get("XDG_STATE_HOME", str(Path.home() / ".local/state")))
    root = root / "cmux/worktrunk-sessions"
    root.mkdir(parents=True, exist_ok=True)
    return root


@contextlib.contextmanager
def locked(path):
    with path.with_suffix(".lock").open("a") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        yield


def read_state(path):
    return json.loads(path.read_text()) if path.exists() else None


def save_state(path, state):
    temporary = path.with_suffix(f".{os.getpid()}.tmp")
    try:
        temporary.write_text(json.dumps(state) + "\n")
        temporary.replace(path)
    finally:
        temporary.unlink(missing_ok=True)


def restore(path, state):
    info = workspace_info(state["workspace"])
    if info is not None:
        surfaces = json.loads(cmux("rpc", "surface.list", json.dumps({
            "workspace_id": state["workspace"],
        })))["surfaces"]
        if any(row["id"].lower() == state["surface"].lower() for row in surfaces):
            report_directory(state["workspace"], state["surface"], state["repo"])
        # Preserve a manual rename made after the hook assigned its title.
        if info.get("custom_title") == state["title"]:
            cmux("rename-workspace", "--workspace", state["workspace"], state["original_title"])
    path.unlink(missing_ok=True)


def bind(directory):
    workspace = str(uuid.UUID(os.environ["CMUX_WORKSPACE_ID"]))
    surface = str(uuid.UUID(os.environ["CMUX_SURFACE_ID"]))
    directory = str(Path(command("git", "-C", directory, "rev-parse", "--show-toplevel")).resolve())
    branch = command("git", "-C", directory, "symbolic-ref", "--short", "HEAD")
    if branch.startswith(("agent-", "worktree-agent-")):
        return
    # The first porcelain entry is Git's primary worktree. -z preserves paths
    # containing spaces, quotes, or backslashes without Git's C-style quoting.
    listing = command("git", "-C", directory, "worktree", "list", "--porcelain", "-z")
    repo = str(Path(listing.split("\0", 1)[0].removeprefix("worktree ")).resolve())
    path = state_root() / f"{workspace}.json"
    with locked(path):
        previous = read_state(path)
        if directory == repo:
            if previous:
                if previous["repo"] != repo:
                    previous.update(repo=repo, surface=surface, original_title=Path(repo).name)
                    save_state(path, previous)
                restore(path, previous)
            return
        info = workspace_info(workspace)
        if info is None:
            return
        title = f"{Path(repo).name} · {branch}"
        if previous and previous["repo"] == repo:
            original = previous["original_title"]
        elif previous and info.get("custom_title") == previous["title"]:
            original = Path(repo).name
        else:
            original = info.get("custom_title") or Path(repo).name
        state = dict(workspace=workspace, surface=surface, directory=directory,
                     repo=repo, title=title, original_title=original)
        # Record first so removal can recover a partially completed bind.
        save_state(path, state)
        report_directory(workspace, surface, directory, repo)
        cmux("rename-workspace", "--workspace", workspace, title)


def remove(directory):
    directory = str(Path(directory).resolve())
    for path in state_root().glob("*.json"):
        with locked(path):
            state = read_state(path)
            if state and state["directory"] == directory:
                restore(path, state)


def main():
    if not all(os.environ.get(key) for key in (
        "CMUX_WORKSPACE_ID", "CMUX_SURFACE_ID", "CMUX_SOCKET_PATH",
    )):
        return
    try:
        action, directory = sys.argv[1:]
        {"bind": bind, "remove": remove}[action](directory)
    except (OSError, ValueError, KeyError, RuntimeError, subprocess.SubprocessError):
        # Sidebar integration must never abort Git work or expose command
        # payloads (which may contain the inherited socket capability).
        print("cmux: session worktree update failed; retry with wt switch", file=sys.stderr)


if __name__ == "__main__":
    main()
