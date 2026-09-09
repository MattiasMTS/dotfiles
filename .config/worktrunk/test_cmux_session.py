import importlib.util
import json
import os
from pathlib import Path
import socket
import subprocess
import tempfile
import threading
import unittest
from unittest.mock import patch


spec = importlib.util.spec_from_file_location("cmux_session", Path(__file__).with_name("cmux-session.py"))
session = importlib.util.module_from_spec(spec)
spec.loader.exec_module(session)

WORKSPACE = "11111111-1111-1111-1111-111111111111"
OTHER = "22222222-2222-2222-2222-222222222222"
SURFACE = "33333333-3333-3333-3333-333333333333"


class SessionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name).resolve()
        self.repo = self.root / 'repo with "quotes"'
        self.repo.mkdir()
        self.git("init", "-b", "main")
        self.git("-c", "user.name=Test", "-c", "user.email=test@example.com", "commit", "--allow-empty", "-m", "initial")
        self.one = self.root / 'worktree "one"'
        self.two = self.root / "worktree two"
        self.git("worktree", "add", "-b", "ms/feature-one", str(self.one))
        self.git("worktree", "add", "-b", "ms/feature-two", str(self.two))
        self.titles = {WORKSPACE: None, OTHER: "My session"}
        self.reports = []
        self.env = patch.dict(os.environ, {
            "XDG_STATE_HOME": str(self.root / "state"),
            "CMUX_WORKSPACE_ID": WORKSPACE,
            "CMUX_SURFACE_ID": SURFACE,
        })
        self.env.start()
        self.addCleanup(self.env.stop)
        self.cli = patch.object(session, "cmux", side_effect=self.cmux)
        self.cli.start()
        self.addCleanup(self.cli.stop)
        self.report = patch.object(session, "report_directory", side_effect=lambda *args: self.reports.append(args))
        self.report.start()
        self.addCleanup(self.report.stop)

    def git(self, *args):
        return subprocess.check_output(["git", "-C", str(self.repo), *args], stderr=subprocess.DEVNULL)

    def cmux(self, *args):
        if args[:2] == ("rpc", "window.list"):
            return json.dumps({"windows": [{"id": "first"}, {"id": "second"}]})
        if args[:2] == ("rpc", "workspace.list"):
            if json.loads(args[2])["window_id"] == "first":
                return json.dumps({"workspaces": []})
            return json.dumps({"workspaces": [dict(id=k, custom_title=v) for k, v in self.titles.items()]})
        if args[:2] == ("rpc", "surface.list"):
            return json.dumps({"surfaces": [{"id": SURFACE}]})
        if args[0] == "rename-workspace":
            self.titles[args[2]] = args[3]
            return "OK"
        raise AssertionError(args)

    def test_two_sessions_in_same_repo_are_independent(self):
        session.bind(str(self.one))
        with patch.dict(os.environ, CMUX_WORKSPACE_ID=OTHER):
            session.bind(str(self.two))
        self.assertEqual(self.reports, [
            (WORKSPACE, SURFACE, str(self.one), str(self.repo)),
            (OTHER, SURFACE, str(self.two), str(self.repo)),
        ])
        self.assertTrue(self.titles[WORKSPACE].endswith("ms/feature-one"))
        self.assertTrue(self.titles[OTHER].endswith("ms/feature-two"))
        session.remove(str(self.one))
        self.assertEqual(self.titles[WORKSPACE], self.repo.name)
        self.assertTrue(self.titles[OTHER].endswith("ms/feature-two"))

    def test_removing_previous_worktree_does_not_clear_new_binding(self):
        session.bind(str(self.one))
        session.bind(str(self.two))
        self.reports.clear()
        session.remove(str(self.one))
        self.assertEqual(self.reports, [])
        self.assertTrue(self.titles[WORKSPACE].endswith("ms/feature-two"))

    def test_cleanup_works_after_git_has_removed_worktree(self):
        session.bind(str(self.one))
        self.git("worktree", "remove", str(self.one))
        session.remove(str(self.one))
        self.assertEqual(self.reports[-1], (WORKSPACE, SURFACE, str(self.repo)))
        self.assertEqual(list(session.state_root().glob("*.json")), [])

    def test_switch_to_main_restores_original_custom_title(self):
        with patch.dict(os.environ, CMUX_WORKSPACE_ID=OTHER):
            session.bind(str(self.one))
            session.bind(str(self.two))
            session.bind(str(self.repo))
        self.assertEqual(self.titles[OTHER], "My session")
        self.assertEqual(self.reports[-1], (OTHER, SURFACE, str(self.repo)))

    def test_cleanup_preserves_later_manual_rename(self):
        session.bind(str(self.one))
        self.titles[WORKSPACE] = "Keep this name"
        session.remove(str(self.one))
        self.assertEqual(self.titles[WORKSPACE], "Keep this name")

    def different_repo(self):
        repo = self.root / "different-repo"
        repo.mkdir()
        for args in [("init", "-b", "main"), (
            "-c", "user.name=Test", "-c", "user.email=test@example.com",
            "commit", "--allow-empty", "-m", "initial",
        )]:
            subprocess.check_output(["git", "-C", str(repo), *args], stderr=subprocess.DEVNULL)
        return repo

    def test_switch_to_another_repos_main_uses_destination(self):
        session.bind(str(self.one))
        repo = self.different_repo()
        session.bind(str(repo))
        self.assertEqual(self.reports[-1], (WORKSPACE, SURFACE, str(repo)))
        self.assertEqual(self.titles[WORKSPACE], repo.name)
        self.assertEqual(list(session.state_root().glob("*.json")), [])

    def test_switch_between_repos_restores_the_new_repo_on_removal(self):
        session.bind(str(self.one))
        repo = self.different_repo()
        worktree = self.root / "different-feature"
        subprocess.check_output([
            "git", "-C", str(repo), "worktree", "add", "-b", "ms/new-feature", str(worktree),
        ], stderr=subprocess.DEVNULL)
        session.bind(str(worktree))
        session.remove(str(worktree))
        self.assertEqual(self.reports[-1], (WORKSPACE, SURFACE, str(repo)))
        self.assertEqual(self.titles[WORKSPACE], repo.name)

    def test_closed_workspace_only_cleans_saved_binding(self):
        session.bind(str(self.one))
        del self.titles[WORKSPACE]
        self.reports.clear()
        session.remove(str(self.one))
        self.assertEqual(self.reports, [])
        self.assertEqual(list(session.state_root().glob("*.json")), [])

    def test_no_op_outside_cmux(self):
        with patch.dict(os.environ, {}, clear=True):
            session.main()
        self.assertEqual(self.reports, [])


class TransportTests(unittest.TestCase):
    def test_socket_envelope_and_quoted_path(self):
        with tempfile.TemporaryDirectory() as root:
            path = str(Path(root) / "socket")
            with socket.socket(socket.AF_UNIX) as server:
                server.bind(path)
                server.listen()
                server.settimeout(3)
                received = []

                def accept():
                    connection, _ = server.accept()
                    with connection:
                        connection.settimeout(3)
                        received.append(connection.recv(65536).decode())
                        connection.sendall(b"OK\n")

                thread = threading.Thread(target=accept)
                thread.start()
                try:
                    with patch.dict(os.environ, CMUX_SOCKET_PATH=path, CMUX_SOCKET_CAPABILITY="test-capability"):
                        session.report_directory(WORKSPACE, SURFACE, '/tmp/worktree "quoted"', "/tmp/repo")
                finally:
                    thread.join(timeout=4)
                self.assertFalse(thread.is_alive())
                self.assertEqual(received, [
                    '_cmux_capability_v1 test-capability report_pwd "/tmp/repo" '
                    '--path="/tmp/worktree \\"quoted\\"" '
                    f'--tab={WORKSPACE} --panel={SURFACE}\n'
                ])


if __name__ == "__main__":
    unittest.main()
