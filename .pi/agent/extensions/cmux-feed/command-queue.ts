import { spawn, type ChildProcessWithoutNullStreams } from "node:child_process";

export interface CommandResult {
	ok: boolean;
	stdout: string;
	timedOut: boolean;
}

export interface CommandOptions {
	timeoutMs: number;
	killGraceMs: number;
	spawnCommand?: typeof spawn;
}

export function executeCommand(
	executable: string,
	args: readonly string[],
	options: CommandOptions,
): Promise<CommandResult> {
	return new Promise((resolve) => {
		let stdout = "";
		let timedOut = false;
		let processError = false;
		let settled = false;
		let timeout: ReturnType<typeof setTimeout> | undefined;
		let killTimer: ReturnType<typeof setTimeout> | undefined;
		let finalKillTimer: ReturnType<typeof setTimeout> | undefined;

		const finish = (result: CommandResult) => {
			if (settled) return;
			settled = true;
			if (timeout) clearTimeout(timeout);
			if (killTimer) clearTimeout(killTimer);
			if (finalKillTimer) clearTimeout(finalKillTimer);
			resolve(result);
		};

		try {
			const spawnCommand = options.spawnCommand ?? spawn;
			const child = spawnCommand(executable, [...args], {
				stdio: ["ignore", "pipe", "ignore"],
			}) as unknown as ChildProcessWithoutNullStreams;
			child.stdout.setEncoding("utf8");
			child.stdout.on("data", (chunk: string) => {
				stdout += chunk;
			});
			child.on("error", () => {
				processError = true;
				// A spawn failure has no process that could commit after resolution.
				if (child.pid === undefined) finish({ ok: false, stdout, timedOut });
			});
			child.on("close", (code) => {
				finish({ ok: !timedOut && !processError && code === 0, stdout, timedOut });
			});

			timeout = setTimeout(() => {
				timedOut = true;
				child.kill("SIGTERM");
				killTimer = setTimeout(() => {
					child.kill("SIGKILL");
					// Node normally emits close after SIGKILL. Keep shutdown bounded if a
					// broken child implementation never does; SIGKILL prevents later commits.
					finalKillTimer = setTimeout(
						() => finish({ ok: false, stdout, timedOut: true }),
						options.killGraceMs,
					);
				}, options.killGraceMs);
			}, options.timeoutMs);
		} catch {
			finish({ ok: false, stdout, timedOut: false });
		}
	});
}

export class SerialCommandQueue {
	private tail: Promise<void> = Promise.resolve();

	enqueue(task: () => Promise<void>): Promise<void> {
		const next = this.tail.then(async () => {
			try {
				await task();
			} catch {
				// A rejected command must not poison later ordered effects.
			}
		});
		this.tail = next;
		return next;
	}
}
