import assert from "node:assert/strict";
import test from "node:test";
import { gitWorkspaceRenameTarget, repositoryNameFromRemote } from "./workspace-title.ts";

test("renames an unnamed workspace to its Git checkout basename", () => {
	assert.equal(gitWorkspaceRenameTarget("lovable", false, "/src/lovable-2"), "lovable-2");
});

test("corrects a custom generic repository title without hardcoded names", () => {
	assert.equal(
		gitWorkspaceRenameTarget("lovable", true, "/src/lovable-3", "lovable"),
		"lovable-3",
	);
});

test("keeps normal repositories and already-correct checkout names", () => {
	assert.equal(
		gitWorkspaceRenameTarget("dotfiles", false, "/src/dotfiles", "dotfiles"),
		undefined,
	);
	assert.equal(
		gitWorkspaceRenameTarget("lovable-2", true, "/src/lovable-2", "lovable"),
		undefined,
	);
});

test("preserves explicit or topic-based custom workspace names", () => {
	assert.equal(
		gitWorkspaceRenameTarget("encryption rollout", true, "/src/lovable-2", "lovable"),
		undefined,
	);
});

test("extracts repository names from common remote URL formats", () => {
	assert.equal(repositoryNameFromRemote("git@github.com:lovablelabs/lovable.git\n"), "lovable");
	assert.equal(repositoryNameFromRemote("https://github.com/org/project.git"), "project");
	assert.equal(repositoryNameFromRemote("/srv/git/local-repo.git/"), "local-repo");
	assert.equal(repositoryNameFromRemote(""), undefined);
});

test("handles command newlines and missing Git metadata", () => {
	assert.equal(
		gitWorkspaceRenameTarget("project", false, "/src/project-review\n"),
		"project-review",
	);
	assert.equal(gitWorkspaceRenameTarget("project", false, ""), undefined);
});
