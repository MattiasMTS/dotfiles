import assert from "node:assert/strict";
import { EventEmitter } from "node:events";
import { PassThrough } from "node:stream";
import test from "node:test";
import type { spawn } from "node:child_process";
import { executeCommand, SerialCommandQueue } from "./command-queue.ts";

class FakeChild extends EventEmitter {
	readonly stdout = new PassThrough();
	readonly signals: NodeJS.Signals[] = [];
	closed = false;
	private readonly closesAfterKill: boolean;

	constructor(closesAfterKill = true) {
		super();
		this.closesAfterKill = closesAfterKill;
	}

	kill(signal: NodeJS.Signals = "SIGTERM"): boolean {
		this.signals.push(signal);
		if (signal === "SIGKILL" && this.closesAfterKill) {
			setTimeout(() => {
				this.closed = true;
				this.emit("close", null);
			}, 5);
		}
		return true;
	}
}

test("queue continues in FIFO order after a rejected command", async () => {
	const queue = new SerialCommandQueue();
	const events: string[] = [];
	const first = queue.enqueue(async () => {
		events.push("first:start");
		throw new Error("expected");
	});
	const second = queue.enqueue(async () => {
		events.push("second:start");
	});
	await Promise.all([first, second]);
	assert.deepEqual(events, ["first:start", "second:start"]);
});

test("timed-out process closes before the queue starts the next command", async () => {
	const queue = new SerialCommandQueue();
	const child = new FakeChild();
	const events: string[] = [];
	const spawnCommand = (() => child) as unknown as typeof spawn;

	const first = queue.enqueue(async () => {
		events.push("first:start");
		const result = await executeCommand("cmux", ["slow"], {
			timeoutMs: 5,
			killGraceMs: 5,
			spawnCommand,
		});
		assert.equal(result.timedOut, true);
		events.push(`first:closed:${child.closed}`);
	});
	const second = queue.enqueue(async () => {
		events.push(`second:start:${child.closed}`);
	});

	await Promise.all([first, second]);
	assert.deepEqual(child.signals, ["SIGTERM", "SIGKILL"]);
	assert.deepEqual(events, ["first:start", "first:closed:true", "second:start:true"]);
});

test("timed-out process has a bounded fallback when close never arrives", async () => {
	const child = new FakeChild(false);
	const result = await executeCommand("cmux", ["stuck"], {
		timeoutMs: 5,
		killGraceMs: 5,
		spawnCommand: (() => child) as unknown as typeof spawn,
	});

	assert.equal(result.ok, false);
	assert.equal(result.timedOut, true);
	assert.deepEqual(child.signals, ["SIGTERM", "SIGKILL"]);
});
