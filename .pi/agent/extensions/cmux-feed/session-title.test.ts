import assert from "node:assert/strict";
import test from "node:test";
import { firstUserPrompt, normalizeSessionTitle, SessionTitleResolver } from "./session-title.ts";

function message(role: string, content: unknown): unknown {
	return { type: "message", message: { role, content } };
}

test("explicit name wins and clearing it reveals the persisted first prompt", () => {
	const resolver = new SessionTitleResolver();
	assert.equal(
		resolver.reset("  Review   auth  ", [message("user", "Fix login failures")], "/repo/app"),
		"Review auth",
	);
	assert.equal(resolver.setExplicitName(undefined), "Fix login failures");
});

test("reads the first meaningful user prompt from the active branch", () => {
	const branch = [
		message("assistant", "not this"),
		message("user", [{ type: "image", data: "..." }]),
		message("user", [
			{ type: "text", text: "  First line " },
			{ type: "image", data: "..." },
			{ type: "text", text: "second line" },
		]),
		message("user", "later prompt"),
	];
	assert.equal(firstUserPrompt(branch), "First line second line");
});

test("captures the first live prompt once when persisted history is empty", () => {
	const resolver = new SessionTitleResolver();
	assert.equal(resolver.reset(undefined, [], "/repo/app"), "pi · app");
	assert.equal(resolver.capturePrompt("Describe the API"), "Describe the API");
	assert.equal(resolver.capturePrompt("A later turn"), "Describe the API");
});

test("session reset drops the previous prompt and resolves the resumed branch", () => {
	const resolver = new SessionTitleResolver();
	resolver.reset(undefined, [message("user", "Old session")], "/repo/old");
	assert.equal(
		resolver.reset(undefined, [message("user", "Resumed branch")], "/repo/new"),
		"Resumed branch",
	);
});

test("branch navigation recomputes the prompt while retaining an explicit name", () => {
	const resolver = new SessionTitleResolver();
	resolver.reset("Named session", [message("user", "Old branch")], "/repo/app");
	assert.equal(resolver.setBranch([message("user", "New branch")]), "Named session");
	assert.equal(resolver.setExplicitName(""), "New branch");
});

test("sanitizes and truncates cwd fallbacks including filesystem root", () => {
	const resolver = new SessionTitleResolver();
	assert.equal(resolver.reset(undefined, [], "/repo/dotfiles"), "pi · dotfiles");
	assert.equal(resolver.reset(undefined, [], "/"), "pi · /");
	assert.equal(
		resolver.reset(undefined, [], "/tmp/Fix\n\u2062codec\u2063title\u2064"),
		"pi · Fix codec title",
	);
	const overlong = resolver.reset(undefined, [], `/tmp/${"x".repeat(80)}`);
	assert.equal(Array.from(overlong).length, 48);
	assert.equal(overlong, `pi · ${"x".repeat(42)}…`);
});

test("normalizes controls and reserved codec markers", () => {
	assert.equal(
		normalizeSessionTitle("  Fix\ncmux\u0000 title\u2062with\u2063markers\u2064  "),
		"Fix cmux title with markers",
	);
	assert.equal(normalizeSessionTitle("\n\t\u2063"), undefined);
});

test("truncates to 48 Unicode code points with a single ellipsis", () => {
	const input = `${"😀".repeat(47)}ab`;
	const title = normalizeSessionTitle(input);
	assert.equal(Array.from(title ?? "").length, 48);
	assert.equal(title, `${"😀".repeat(47)}…`);
});
