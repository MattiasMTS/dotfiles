import assert from "node:assert/strict";
import test from "node:test";
import {
	createFeedState,
	formatOwnedTitle,
	OWNED_TITLE_SEPARATOR,
	parseOwnedTitle,
	reduceFeedState,
	stripOwnedTitle,
} from "./state.ts";

function runningState(generation = 1) {
	return reduceFeedState(createFeedState(), {
		type: "run_started",
		generation,
		startedAt: 100,
	});
}

test("settles only for the current generation when Pi is idle", () => {
	const running = runningState(2);
	const outcome = {
		type: "agent_settled" as const,
		outcome: "completed" as const,
		summary: "done",
	};

	assert.equal(reduceFeedState(running, { ...outcome, generation: 1, isIdle: true }), running);
	assert.equal(reduceFeedState(running, { ...outcome, generation: 2, isIdle: false }), running);
	assert.equal(
		reduceFeedState(running, { ...outcome, generation: 2, isIdle: true }).lifecycle,
		"completed",
	);
});

test("tracks concurrent tools by toolCallId and ignores unknown/stale ends", () => {
	let state = runningState(3);
	state = reduceFeedState(state, {
		type: "tool_started",
		generation: 3,
		toolCallId: "a",
		toolName: "read",
	});
	state = reduceFeedState(state, {
		type: "tool_started",
		generation: 3,
		toolCallId: "b",
		toolName: "bash",
	});
	const unchanged = reduceFeedState(state, {
		type: "tool_ended",
		generation: 2,
		toolCallId: "a",
	});
	assert.equal(unchanged, state);

	state = reduceFeedState(state, { type: "tool_ended", generation: 3, toolCallId: "a" });
	assert.deepEqual(state.activeTools, { b: "bash" });
	assert.equal(
		reduceFeedState(state, { type: "tool_ended", generation: 3, toolCallId: "missing" }),
		state,
	);
});

test("progress clear cannot erase terminal error or cancellation", () => {
	for (const outcome of ["error", "cancelled"] as const) {
		const terminal = reduceFeedState(runningState(), {
			type: "agent_settled",
			generation: 1,
			isIdle: true,
			outcome,
			summary: outcome,
		});
		const cleared = reduceFeedState(terminal, { type: "progress_cleared", generation: 1 });
		assert.equal(cleared.lifecycle, outcome);
		assert.equal(cleared.terminalSummary, outcome);
	}
});

test("reload preserves terminal state while new, resume, and fork reset it", () => {
	const terminal = reduceFeedState(runningState(), {
		type: "agent_settled",
		generation: 1,
		isIdle: true,
		outcome: "error",
		summary: "failed",
	});
	const reloaded = reduceFeedState(terminal, {
		type: "session_started",
		generation: 2,
		reason: "reload",
	});
	assert.equal(reloaded.lifecycle, "error");

	for (const reason of ["new", "resume", "fork"] as const) {
		assert.equal(
			reduceFeedState(reloaded, {
				type: "session_started",
				generation: 3,
				reason,
			}).lifecycle,
			"idle",
		);
	}
});

test("fresh runtime reload hydrates terminal title state without winning a newer run race", () => {
	for (const lifecycle of ["completed", "error", "cancelled"] as const) {
		const started = reduceFeedState(createFeedState(), {
			type: "session_started",
			generation: 1,
			reason: "reload",
		});
		assert.equal(started.lifecycle, "idle");
		assert.equal(
			reduceFeedState(started, {
				type: "lifecycle_hydrated",
				generation: 1,
				lifecycle,
			}).lifecycle,
			lifecycle,
		);

		const newerRun = reduceFeedState(started, {
			type: "run_started",
			generation: 2,
			startedAt: 200,
		});
		assert.equal(
			reduceFeedState(newerRun, {
				type: "lifecycle_hydrated",
				generation: 1,
				lifecycle,
			}),
			newerRun,
		);
	}
});

test("owned title codec is exact and round-trips Unicode separators", () => {
	const automaticBase = `${OWNED_TITLE_SEPARATOR}π · work${OWNED_TITLE_SEPARATOR}tree`;
	const manualBase = `my ${OWNED_TITLE_SEPARATOR} tab 🚀`;
	const automatic = formatOwnedTitle("completed", automaticBase, false);
	const manual = formatOwnedTitle("error", manualBase, true);
	assert.deepEqual(parseOwnedTitle(automatic), {
		state: "completed",
		baseTitle: automaticBase,
		preservesManualTitle: false,
	});
	assert.deepEqual(parseOwnedTitle(manual), {
		state: "error",
		baseTitle: manualBase,
		preservesManualTitle: true,
	});
	assert.equal(stripOwnedTitle(automatic), automaticBase);
	assert.equal(stripOwnedTitle(manual), manualBase);
	assert.equal(stripOwnedTitle("✓ ordinary title"), "✓ ordinary title");
	assert.equal(parseOwnedTitle("✓ ordinary title"), undefined);
});

test("owned title codec remains backward compatible with legacy markers", () => {
	const legacyAutomatic = `✓${OWNED_TITLE_SEPARATOR}pi`;
	const legacyManual = `!${OWNED_TITLE_SEPARATOR}${OWNED_TITLE_SEPARATOR}my tab`;
	assert.deepEqual(parseOwnedTitle(legacyAutomatic), {
		state: "completed",
		baseTitle: "pi",
		preservesManualTitle: false,
	});
	assert.deepEqual(parseOwnedTitle(legacyManual), {
		state: "error",
		baseTitle: "my tab",
		preservesManualTitle: true,
	});
});

test("stale run and session events cannot replace a newer generation", () => {
	const current = runningState(4);
	assert.equal(
		reduceFeedState(current, { type: "run_started", generation: 3, startedAt: 200 }),
		current,
	);
	assert.equal(
		reduceFeedState(current, {
			type: "session_started",
			generation: 4,
			reason: "new",
		}),
		current,
	);
});
