import assert from "node:assert/strict";
import test from "node:test";
import { formatOwnedTitle } from "./state.ts";
import { TitleOwner, type TitleIO } from "./title-owner.ts";

test("acquires an automatic title using the derived session base", async () => {
	let title: string | undefined = "pi";
	const io: TitleIO = {
		read: async () => title,
		clear: async () => true,
		rename: async (requested) => {
			title = requested;
			return true;
		},
	};
	const owner = new TitleOwner(io);
	await owner.recoverOrReset("startup", "Fix cmux titles");

	assert.equal(title, formatOwnedTitle("idle", "Fix cmux titles", false));
});

test("rebases automatic titles without changing their lifecycle state", async () => {
	let title: string | undefined = "pi";
	const io: TitleIO = {
		read: async () => title,
		clear: async () => true,
		rename: async (requested) => {
			title = requested;
			return true;
		},
	};
	const owner = new TitleOwner(io);
	await owner.recoverOrReset("startup", "Old title");
	await owner.mark("running", false, "Old title");
	await owner.mark("running", false, "New title");

	assert.equal(title, formatOwnedTitle("running", "New title", false));
});

test("reacquires after Pi OSC mutates an extension-owned automatic title", async () => {
	let title: string | undefined = "pi";
	const io: TitleIO = {
		read: async () => title,
		clear: async () => true,
		rename: async (requested) => {
			title = requested;
			return true;
		},
	};
	const owner = new TitleOwner(io);
	await owner.recoverOrReset("startup", "Old title");
	title = "Pi automatic OSC title";
	await owner.mark("running", true, "Explicit session name");

	assert.equal(title, formatOwnedTitle("running", "Explicit session name", false));
});

test("reacquisition restores a genuine manual override instead of replacing it", async () => {
	let title: string | undefined = "pi";
	const io: TitleIO = {
		read: async () => title,
		clear: async () => {
			if (title === "Manual override") title = "Pi automatic OSC title";
			return true;
		},
		rename: async (requested) => {
			title = requested;
			return true;
		},
	};
	const owner = new TitleOwner(io);
	await owner.recoverOrReset("startup", "Old title");
	title = "Manual override";
	await owner.mark("running", true, "Explicit session name");

	assert.equal(title, formatOwnedTitle("running", "Manual override", true));
});

test("terminal reload rebases an automatic title without resetting completion", async () => {
	let title: string | undefined = formatOwnedTitle("completed", "Old title", false);
	const io: TitleIO = {
		read: async () => title,
		clear: async () => false,
		rename: async (requested) => {
			title = requested;
			return true;
		},
	};
	const owner = new TitleOwner(io);
	const recovered = await owner.recoverOrReset("reload", "Resumed session");

	assert.equal(recovered, "completed");
	assert.equal(title, formatOwnedTitle("completed", "Resumed session", false));
});

test("derived titles never replace manual plain or manually-owned bases", async () => {
	let title: string | undefined = "My manual tab";
	const io: TitleIO = {
		read: async () => title,
		clear: async () => {
			title = "automatic";
			return true;
		},
		rename: async (requested) => {
			title = requested;
			return true;
		},
	};
	const owner = new TitleOwner(io);
	await owner.recoverOrReset("startup", "Derived title");
	assert.equal(title, formatOwnedTitle("idle", "My manual tab", true));

	await owner.mark("completed", false, "Another derived title");
	assert.equal(title, formatOwnedTitle("completed", "My manual tab", true));
});

test("reconciles failed manual-title probe rollback and marker rename", async () => {
	let title: string | undefined = "my tab";
	let renameCount = 0;
	const io: TitleIO = {
		read: async () => title,
		clear: async () => {
			title = "automatic";
			return false;
		},
		rename: async (requested) => {
			renameCount += 1;
			title = requested;
			return false;
		},
	};
	const owner = new TitleOwner(io);
	await owner.recoverOrReset("startup");

	assert.equal(renameCount, 2);
	assert.equal(owner.titleWritesDisabled, false);
	assert.equal(owner.expectedTitle, formatOwnedTitle("idle", "my tab", true));
});

test("restores the original title when the post-clear ownership read fails", async () => {
	let title: string | undefined = "manual";
	let readCount = 0;
	let renameCount = 0;
	const io: TitleIO = {
		read: async () => {
			readCount += 1;
			return readCount === 3 ? undefined : title;
		},
		clear: async () => {
			title = "automatic";
			return true;
		},
		rename: async (requested) => {
			renameCount += 1;
			title = requested;
			return true;
		},
	};
	const owner = new TitleOwner(io);
	await owner.recoverOrReset("startup");

	assert.equal(owner.titleWritesDisabled, true);
	assert.equal(owner.expectedTitle, undefined);
	assert.equal(renameCount, 1);
	assert.equal(title, "manual");
});

test("disables title writes when destructive manual-title rollback cannot be verified", async () => {
	let title: string | undefined = "manual";
	const io: TitleIO = {
		read: async () => title,
		clear: async () => {
			title = "automatic";
			return true;
		},
		rename: async () => false,
	};
	const owner = new TitleOwner(io);
	await owner.recoverOrReset("startup");

	assert.equal(owner.titleWritesDisabled, true);
	assert.equal(owner.expectedTitle, undefined);
	assert.equal(title, "automatic");
});

test("records terminal rename ownership when command reports failure but marker landed", async () => {
	let title: string | undefined = formatOwnedTitle("completed", "pi", false);
	const io: TitleIO = {
		read: async () => title,
		clear: async () => false,
		rename: async (requested) => {
			title = requested;
			return false;
		},
	};
	const owner = new TitleOwner(io);
	await owner.recoverOrReset("reload");
	await owner.mark("error", false);

	assert.equal(owner.titleWritesDisabled, false);
	assert.equal(owner.expectedTitle, formatOwnedTitle("error", "pi", false));
});

test("disables further writes but retains old ownership when terminal rename does not land", async () => {
	const completed = formatOwnedTitle("completed", "pi", false);
	let title: string | undefined = completed;
	const io: TitleIO = {
		read: async () => title,
		clear: async () => false,
		rename: async () => false,
	};
	const owner = new TitleOwner(io);
	await owner.recoverOrReset("reload");
	await owner.mark("error", false);

	assert.equal(owner.titleWritesDisabled, true);
	assert.equal(owner.expectedTitle, completed);
});

test("reconciles failed automatic release when clear actually landed", async () => {
	const completed = formatOwnedTitle("completed", "pi", false);
	let title: string | undefined = completed;
	const io: TitleIO = {
		read: async () => title,
		clear: async () => {
			title = "pi";
			return false;
		},
		rename: async () => false,
	};
	const owner = new TitleOwner(io);
	await owner.recoverOrReset("reload");
	await owner.release();

	assert.equal(owner.titleWritesDisabled, false);
	assert.equal(owner.expectedTitle, undefined);
	assert.equal(title, "pi");
});
