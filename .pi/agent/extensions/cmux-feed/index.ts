/**
 * cmux lifecycle, notification, and sidebar progress feed for Pi.
 *
 * Keeps cmux's native Pi session lifecycle/restore integration, adds concise
 * native completion notifications, and publishes live workspace progress
 * consumed by the custom repos sidebar. Completion summaries include duration
 * once a run reaches PI_CMUX_NOTIFY_THRESHOLD_MS (15 seconds by default).
 *
 * Lifecycle hook delivery is bounded and synchronous so Pi does not exit or
 * settle before cmux receives completion state. Progress updates are detached
 * and best-effort. A missing, slow, or broken cmux can never crash Pi.
 */

import { spawn, spawnSync } from "node:child_process";
import * as path from "node:path";
import {
	isBashToolResult,
	isEditToolResult,
	isFindToolResult,
	isGrepToolResult,
	isReadToolResult,
	isWriteToolResult,
	type ExtensionAPI,
	type ExtensionContext,
	type ToolResultEvent,
} from "@earendil-works/pi-coding-agent";

const DEFAULT_NOTIFY_THRESHOLD_MS = 15_000;
const FINAL_PROGRESS_CLEAR_MS = 10_000;
const HOOK_TIMEOUT_MS = 5_000;
const MAX_PROGRESS_LABEL_LENGTH = 120;

const HOOK_EVENT_NAMES = {
	"session-start": "SessionStart",
	"prompt-submit": "UserPromptSubmit",
	stop: "Stop",
} as const;

type HookSubcommand = keyof typeof HOOK_EVENT_NAMES;

interface RunState {
	startedAt: number;
	readFiles: Set<string>;
	changedFiles: Set<string>;
	searchCount: number;
	bashCount: number;
	toolCount: number;
	turnCount: number;
	firstToolError?: string;
}

interface AssistantMessageLike {
	role: "assistant";
	stopReason?: string;
	errorMessage?: string;
	content?: unknown;
}

interface RunFailure {
	kind: "error" | "cancelled";
	summary: string;
}

function cmuxExecutable(): string {
	return process.env.CMUX_PI_CMUX_BIN || process.env.CMUX_BUNDLED_CLI_PATH || "cmux";
}

function cmuxEnabled(): boolean {
	return Boolean(process.env.CMUX_SURFACE_ID) && process.env.CMUX_PI_HOOKS_DISABLED !== "1";
}

function getNumberFromEnv(name: string, fallback: number): number {
	const value = process.env[name];
	if (!value) return fallback;
	const parsed = Number.parseInt(value, 10);
	return Number.isFinite(parsed) && parsed >= 0 ? parsed : fallback;
}

function truncateText(text: string, maxLength: number): string {
	const normalized = text.replace(/\s+/g, " ").trim();
	return normalized.length > maxLength ? `${normalized.slice(0, maxLength - 3)}...` : normalized;
}

function textFromContent(content: unknown): string | null {
	if (typeof content === "string") return content.trim() || null;
	if (!Array.isArray(content)) return null;

	const parts: string[] = [];
	for (const block of content) {
		if (!block || typeof block !== "object") continue;
		const typed = block as { type?: unknown; text?: unknown };
		if (typed.type === "text" && typeof typed.text === "string") {
			parts.push(typed.text);
		}
	}
	return parts.join("\n").trim() || null;
}

function isAssistantMessage(message: unknown): message is AssistantMessageLike {
	return (
		typeof message === "object" &&
		message !== null &&
		(message as { role?: unknown }).role === "assistant"
	);
}

function lastAssistant(messages: readonly unknown[]): AssistantMessageLike | undefined {
	for (let index = messages.length - 1; index >= 0; index -= 1) {
		const message = messages[index];
		if (isAssistantMessage(message)) return message;
	}
	return undefined;
}

function createRunState(): RunState {
	return {
		startedAt: Date.now(),
		readFiles: new Set<string>(),
		changedFiles: new Set<string>(),
		searchCount: 0,
		bashCount: 0,
		toolCount: 0,
		turnCount: 0,
	};
}

function pluralize(count: number, singular: string, plural: string = `${singular}s`): string {
	return count === 1 ? singular : plural;
}

function formatDuration(ms: number): string {
	const totalSeconds = Math.max(1, Math.round(ms / 1_000));
	const minutes = Math.floor(totalSeconds / 60);
	const seconds = totalSeconds % 60;
	if (minutes === 0) return `${seconds}s`;
	if (seconds === 0) return `${minutes}m`;
	return `${minutes}m ${seconds}s`;
}

function getPathFromInput(event: ToolResultEvent): string | undefined {
	const inputPath = event.input.path;
	return typeof inputPath === "string" && inputPath.length > 0 ? inputPath : undefined;
}

function getFirstText(event: ToolResultEvent): string | undefined {
	const textPart = event.content.find((part) => part.type === "text");
	if (!textPart || textPart.type !== "text") return undefined;
	const text = textPart.text.trim();
	return text.length > 0 ? text : undefined;
}

function summarizeToolError(event: ToolResultEvent): string {
	const inputPath = getPathFromInput(event);
	if (inputPath) return `${event.toolName} failed for ${path.basename(inputPath)}`;
	if (isBashToolResult(event)) return "bash command failed";
	const text = getFirstText(event);
	return text ? truncateText(text, 120) : `${event.toolName} failed`;
}

function summarizeSuccess(state: RunState, durationMs: number, thresholdMs: number): string {
	const withDuration = (summary: string): string =>
		durationMs >= thresholdMs ? `${summary} in ${formatDuration(durationMs)}` : summary;

	if (state.changedFiles.size === 1) {
		return withDuration(`Updated ${path.basename([...state.changedFiles][0])}`);
	}
	if (state.changedFiles.size > 1) {
		return withDuration(`Updated ${state.changedFiles.size} files`);
	}
	if (state.readFiles.size === 1) {
		return withDuration(`Reviewed ${path.basename([...state.readFiles][0])}`);
	}
	if (state.readFiles.size > 1) {
		return withDuration(`Reviewed ${state.readFiles.size} files`);
	}
	if (state.searchCount > 0 && state.bashCount > 0) {
		return withDuration(
			`Ran ${state.searchCount} ${pluralize(state.searchCount, "search")} and ${state.bashCount} ${pluralize(state.bashCount, "shell command")}`,
		);
	}
	if (state.searchCount > 0) {
		return withDuration(
			state.searchCount === 1 ? "Searched the codebase" : `Ran ${state.searchCount} searches`,
		);
	}
	if (state.bashCount > 0) {
		return withDuration(
			`Ran ${state.bashCount} ${pluralize(state.bashCount, "shell command")}`,
		);
	}
	return durationMs >= thresholdMs
		? `Finished in ${formatDuration(durationMs)}`
		: "Finished and waiting for input";
}

function summarizeRunFailure(
	messages: readonly unknown[],
	fallbackError?: string,
): RunFailure | undefined {
	const assistant = lastAssistant(messages);
	if (!assistant) return fallbackError ? { kind: "error", summary: fallbackError } : undefined;
	if (assistant.stopReason !== "error" && assistant.stopReason !== "aborted") return undefined;

	const message =
		assistant.errorMessage?.trim() || textFromContent(assistant.content) || fallbackError;
	if (assistant.stopReason === "aborted") {
		return { kind: "cancelled", summary: truncateText(message || "Operation cancelled", 120) };
	}
	return { kind: "error", summary: truncateText(message || "Agent run failed", 120) };
}

function estimateProgress(state: RunState): number {
	return Math.min(0.9, Math.max(0.08, 0.08 + state.turnCount * 0.14 + state.toolCount * 0.04));
}

function runCmux(args: string[]): void {
	if (!cmuxEnabled()) return;
	const cmux = cmuxExecutable();

	try {
		const child = spawn(cmux, args, {
			detached: true,
			stdio: "ignore",
		});
		child.on("error", () => {});
		child.unref();
	} catch {
		// Sidebar progress is best-effort.
	}
}

function setProgress(value: number, label: string): void {
	runCmux([
		"set-progress",
		Math.min(1, Math.max(0, value)).toFixed(2),
		"--label",
		truncateText(label, MAX_PROGRESS_LABEL_LENGTH),
	]);
}

function clearProgress(): void {
	runCmux(["clear-progress"]);
}

function sendHook(
	subcommand: HookSubcommand,
	ctx: ExtensionContext,
	extra: Record<string, unknown> = {},
): boolean {
	if (!cmuxEnabled()) return true;
	const cmux = cmuxExecutable();

	try {
		const eventName = HOOK_EVENT_NAMES[subcommand];
		const payload = JSON.stringify({
			session_id: ctx.sessionManager.getSessionId(),
			cwd: ctx.cwd || process.cwd(),
			hook_event_name: eventName,
			event: eventName,
			...extra,
		});

		const result = spawnSync(cmux, ["hooks", "pi", subcommand], {
			input: payload,
			encoding: "utf8",
			stdio: ["pipe", "ignore", "ignore"],
			timeout: HOOK_TIMEOUT_MS,
		});
		return !result.error && result.status === 0;
	} catch {
		return false;
	}
}

class CmuxFeedRuntime {
	private readonly notifyThresholdMs = getNumberFromEnv(
		"PI_CMUX_NOTIFY_THRESHOLD_MS",
		DEFAULT_NOTIFY_THRESHOLD_MS,
	);
	private runState = createRunState();
	private runActive = false;
	private activeToolCount = 0;
	private finalProgressTimer: ReturnType<typeof setTimeout> | undefined;

	register(pi: ExtensionAPI): void {
		pi.on("session_start", (_event, ctx) => this.handleSessionStart(ctx));
		pi.on("before_agent_start", (event, ctx) => this.handleAgentStart(event.prompt, ctx));
		pi.on("turn_start", (event) => this.handleTurnStart(event.turnIndex));
		pi.on("tool_execution_start", (event) => this.handleToolStart(event.toolName));
		pi.on("tool_result", (event) => this.handleToolResult(event));
		pi.on("tool_execution_end", () => this.handleToolEnd());
		pi.on("agent_end", (event, ctx) => this.handleAgentEnd(event.messages, ctx));
		pi.on("session_shutdown", (event, ctx) => this.handleSessionShutdown(event.reason, ctx));
	}

	private cancelFinalProgressClear(): void {
		if (!this.finalProgressTimer) return;
		clearTimeout(this.finalProgressTimer);
		this.finalProgressTimer = undefined;
	}

	private scheduleFinalProgressClear(): void {
		this.cancelFinalProgressClear();
		this.finalProgressTimer = setTimeout(() => {
			this.finalProgressTimer = undefined;
			clearProgress();
		}, FINAL_PROGRESS_CLEAR_MS);
		(this.finalProgressTimer as { unref?: () => void }).unref?.();
	}

	private handleSessionStart(ctx: ExtensionContext): void {
		this.cancelFinalProgressClear();
		this.runActive = false;
		this.activeToolCount = 0;
		clearProgress();
		sendHook("session-start", ctx);
	}

	private handleAgentStart(prompt: string, ctx: ExtensionContext): void {
		this.cancelFinalProgressClear();
		this.runState = createRunState();
		this.runActive = true;
		this.activeToolCount = 0;
		setProgress(0.08, "Starting");
		sendHook("prompt-submit", ctx, { prompt });
	}

	private handleTurnStart(turnIndex: number): void {
		if (!this.runActive) return;
		this.runState.turnCount = Math.max(this.runState.turnCount, turnIndex + 1);
		const label = turnIndex > 0 ? `Thinking · turn ${turnIndex + 1}` : "Thinking";
		setProgress(estimateProgress(this.runState), label);
	}

	private handleToolStart(toolName: string): void {
		if (!this.runActive) return;
		this.activeToolCount += 1;
		setProgress(estimateProgress(this.runState), `Using ${toolName}`);
	}

	private handleToolResult(event: ToolResultEvent): void {
		if (!this.runActive) return;
		this.runState.toolCount += 1;

		if (event.isError) {
			if (!this.runState.firstToolError)
				this.runState.firstToolError = summarizeToolError(event);
			return;
		}

		const inputPath = getPathFromInput(event);
		if (isReadToolResult(event)) {
			if (inputPath) this.runState.readFiles.add(inputPath);
		} else if (isEditToolResult(event) || isWriteToolResult(event)) {
			if (inputPath) this.runState.changedFiles.add(inputPath);
		} else if (isGrepToolResult(event) || isFindToolResult(event)) {
			this.runState.searchCount += 1;
		} else if (isBashToolResult(event)) {
			this.runState.bashCount += 1;
		}
	}

	private handleToolEnd(): void {
		if (!this.runActive) return;
		this.activeToolCount = Math.max(0, this.activeToolCount - 1);
		if (this.activeToolCount === 0) setProgress(estimateProgress(this.runState), "Thinking");
	}

	private handleAgentEnd(messages: readonly unknown[], ctx: ExtensionContext): void {
		if (!this.runActive) return;
		this.runActive = false;
		this.activeToolCount = 0;

		const durationMs = Date.now() - this.runState.startedAt;
		const failure = summarizeRunFailure(messages, this.runState.firstToolError);
		const summary =
			failure?.summary || summarizeSuccess(this.runState, durationMs, this.notifyThresholdMs);
		this.publishCompletion(ctx, summary, failure);
	}

	private publishCompletion(ctx: ExtensionContext, summary: string, failure?: RunFailure): void {
		// cmux's Pi stop hook owns notification delivery and unread/latestMessage
		// state. Supplying the concise summary here avoids a second direct
		// `cmux notify` call and therefore avoids duplicate notifications.
		sendHook("stop", ctx, {
			last_assistant_message: summary,
			terminationReason: failure?.kind,
		});

		setProgress(1, this.finalProgressLabel(summary, failure));
		this.scheduleFinalProgressClear();
	}

	private finalProgressLabel(summary: string, failure?: RunFailure): string {
		if (!failure) return `Done · ${summary}`;
		const prefix = failure.kind === "error" ? "Error" : "Cancelled";
		return `${prefix} · ${summary}`;
	}

	private handleSessionShutdown(reason: string, ctx: ExtensionContext): void {
		this.cancelFinalProgressClear();
		clearProgress();
		if (!this.runActive) return;

		this.runActive = false;
		sendHook("stop", ctx, { terminationReason: reason });
	}
}

export default function (pi: ExtensionAPI) {
	new CmuxFeedRuntime().register(pi);
}
