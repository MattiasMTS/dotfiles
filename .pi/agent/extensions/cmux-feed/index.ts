/**
 * Ordered cmux lifecycle, notification, title, and sidebar progress feed for Pi.
 *
 * cmux 0.64.22 has no tabs[].agent metadata. Exact U+2063 title markers are a
 * compatibility projection for the custom sidebar, not the source of truth.
 */

import { spawnSync } from "node:child_process";
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
import { executeCommand, SerialCommandQueue, type CommandResult } from "./command-queue.ts";
import { SessionTitleResolver } from "./session-title.ts";
import {
	createFeedState,
	reduceFeedState,
	type FeedState,
	type RunMetrics,
	type SessionStartReason,
	type TerminalState,
} from "./state.ts";
import { TitleOwner } from "./title-owner.ts";
import { gitWorkspaceRenameTarget, repositoryNameFromRemote } from "./workspace-title.ts";

const DEFAULT_NOTIFY_THRESHOLD_MS = 15_000;
const FINAL_PROGRESS_CLEAR_MS = 10_000;
const HOOK_TIMEOUT_MS = 5_000;
const COMMAND_TIMEOUT_MS = 1_500;
const COMMAND_KILL_GRACE_MS = 250;
const MAX_PROGRESS_LABEL_LENGTH = 120;

const HOOK_EVENT_NAMES = {
	"session-start": "SessionStart",
	"prompt-submit": "UserPromptSubmit",
	stop: "Stop",
} as const;
type HookSubcommand = keyof typeof HOOK_EVENT_NAMES;

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
	return (
		process.env.PI_SUBAGENT_CHILD !== "1" &&
		Boolean(process.env.CMUX_SURFACE_ID) &&
		process.env.CMUX_PI_HOOKS_DISABLED !== "1"
	);
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
		if (typed.type === "text" && typeof typed.text === "string") parts.push(typed.text);
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

function pluralize(count: number, singular: string, plural = `${singular}s`): string {
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

function summarizeSuccess(state: RunMetrics, durationMs: number, thresholdMs: number): string {
	const withDuration = (summary: string): string =>
		durationMs >= thresholdMs ? `${summary} in ${formatDuration(durationMs)}` : summary;
	if (state.changedFiles.size === 1)
		return withDuration(`Updated ${path.basename([...state.changedFiles][0])}`);
	if (state.changedFiles.size > 1)
		return withDuration(`Updated ${state.changedFiles.size} files`);
	if (state.readFiles.size === 1)
		return withDuration(`Reviewed ${path.basename([...state.readFiles][0])}`);
	if (state.readFiles.size > 1) return withDuration(`Reviewed ${state.readFiles.size} files`);
	if (state.searchCount > 0 && state.bashCount > 0) {
		return withDuration(
			`Ran ${state.searchCount} ${pluralize(state.searchCount, "search")} and ${state.bashCount} ${pluralize(state.bashCount, "shell command")}`,
		);
	}
	if (state.searchCount > 0)
		return withDuration(
			state.searchCount === 1 ? "Searched the codebase" : `Ran ${state.searchCount} searches`,
		);
	if (state.bashCount > 0)
		return withDuration(
			`Ran ${state.bashCount} ${pluralize(state.bashCount, "shell command")}`,
		);
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

function estimateProgress(state: RunMetrics): number {
	return Math.min(0.9, Math.max(0.08, 0.08 + state.turnCount * 0.14 + state.toolCount * 0.04));
}

function executeCmux(args: string[]): Promise<CommandResult> {
	if (!cmuxEnabled()) return Promise.resolve({ ok: false, stdout: "", timedOut: false });
	return executeCommand(cmuxExecutable(), args, {
		timeoutMs: COMMAND_TIMEOUT_MS,
		killGraceMs: COMMAND_KILL_GRACE_MS,
	});
}

function executeGit(cwd: string, args: string[]): Promise<CommandResult> {
	return executeCommand("git", ["-C", cwd, ...args], {
		timeoutMs: COMMAND_TIMEOUT_MS,
		killGraceMs: COMMAND_KILL_GRACE_MS,
	});
}

function sendHook(
	subcommand: HookSubcommand,
	ctx: ExtensionContext,
	extra: Record<string, unknown> = {},
): boolean {
	if (!cmuxEnabled()) return true;
	try {
		const eventName = HOOK_EVENT_NAMES[subcommand];
		const payload = JSON.stringify({
			session_id: ctx.sessionManager.getSessionId(),
			cwd: ctx.cwd || process.cwd(),
			hook_event_name: eventName,
			event: eventName,
			...extra,
		});
		const result = spawnSync(cmuxExecutable(), ["hooks", "pi", subcommand], {
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
	private readonly effects = new SerialCommandQueue();
	private readonly notifyThresholdMs = getNumberFromEnv(
		"PI_CMUX_NOTIFY_THRESHOLD_MS",
		DEFAULT_NOTIFY_THRESHOLD_MS,
	);
	private state: FeedState = createFeedState();
	private lastRunMessages: readonly unknown[] = [];
	private messagesGeneration = 0;
	private readonly sessionTitle = new SessionTitleResolver();
	private readonly titleOwner: TitleOwner;
	private finalProgressTimer: ReturnType<typeof setTimeout> | undefined;

	constructor() {
		this.titleOwner = new TitleOwner({
			read: () => this.currentSurfaceTitle(),
			rename: (title) => this.setCurrentSurfaceTitle(title),
			clear: () => this.clearCurrentSurfaceTitle(),
		});
	}

	register(pi: ExtensionAPI): void {
		pi.on("session_start", (event, ctx) => this.handleSessionStart(event.reason, ctx, pi));
		pi.on("session_info_changed", (event) => this.handleSessionInfoChanged(event.name));
		pi.on("session_tree", (_event, ctx) => this.handleSessionTree(ctx));
		pi.on("before_agent_start", (event, ctx) => this.handleAgentStart(event.prompt, ctx));
		pi.on("turn_start", (event) => this.handleTurnStart(event.turnIndex));
		pi.on("tool_execution_start", (event) =>
			this.handleToolStart(event.toolCallId, event.toolName),
		);
		pi.on("tool_result", (event) => this.handleToolResult(event));
		pi.on("tool_execution_end", (event) => this.handleToolEnd(event.toolCallId));
		pi.on("agent_end", (event) => this.handleAgentEnd(event.messages));
		pi.on("agent_settled", (_event, ctx) => this.handleAgentSettled(ctx));
		pi.on("session_shutdown", (event, ctx) => this.handleSessionShutdown(event.reason, ctx));
	}

	private project(task: () => Promise<void>): Promise<void> {
		return this.effects.enqueue(task);
	}

	private setProgress(value: number, label: string): void {
		void this.project(async () => {
			await executeCmux([
				"set-progress",
				Math.min(1, Math.max(0, value)).toFixed(2),
				"--label",
				truncateText(label, MAX_PROGRESS_LABEL_LENGTH),
			]);
		});
	}

	private clearProgress(generation?: number): Promise<void> {
		return this.project(async () => {
			if (generation !== undefined && generation !== this.state.generation) return;
			await executeCmux(["clear-progress"]);
			if (generation !== undefined) {
				this.state = reduceFeedState(this.state, { type: "progress_cleared", generation });
			}
		});
	}

	private cancelFinalProgressClear(): void {
		if (!this.finalProgressTimer) return;
		clearTimeout(this.finalProgressTimer);
		this.finalProgressTimer = undefined;
	}

	private scheduleFinalProgressClear(generation: number): void {
		this.cancelFinalProgressClear();
		this.finalProgressTimer = setTimeout(() => {
			this.finalProgressTimer = undefined;
			if (generation !== this.state.generation || this.state.lifecycle === "running") return;
			void this.clearProgress(generation);
		}, FINAL_PROGRESS_CLEAR_MS);
		this.finalProgressTimer.unref?.();
	}

	private async currentSurfaceTitle(): Promise<string | undefined> {
		const workspaceId = process.env.CMUX_WORKSPACE_ID;
		const surfaceId = process.env.CMUX_SURFACE_ID;
		if (!workspaceId || !surfaceId) return undefined;
		const result = await executeCmux([
			"rpc",
			"surface.list",
			JSON.stringify({ workspace_id: workspaceId }),
		]);
		if (!result.ok || !result.stdout) return undefined;
		try {
			const payload = JSON.parse(result.stdout) as {
				surfaces?: Array<{ id?: unknown; title?: unknown }>;
			};
			const surface = payload.surfaces?.find(
				(candidate) =>
					typeof candidate.id === "string" &&
					candidate.id.toLowerCase() === surfaceId.toLowerCase(),
			);
			return typeof surface?.title === "string" ? surface.title : undefined;
		} catch {
			return undefined;
		}
	}

	private async currentWorkspaceMetadata(
		workspaceId: string,
	): Promise<{ title: string; hasCustomTitle: boolean } | undefined> {
		const result = await executeCmux(["rpc", "workspace.list", "{}"]);
		if (!result.ok || !result.stdout) return undefined;
		try {
			const payload = JSON.parse(result.stdout) as {
				workspaces?: Array<{
					id?: unknown;
					title?: unknown;
					has_custom_title?: unknown;
				}>;
			};
			const workspace = payload.workspaces?.find(
				(candidate) =>
					typeof candidate.id === "string" &&
					candidate.id.toLowerCase() === workspaceId.toLowerCase(),
			);
			if (
				typeof workspace?.title !== "string" ||
				typeof workspace.has_custom_title !== "boolean"
			) {
				return undefined;
			}
			return {
				title: workspace.title,
				hasCustomTitle: workspace.has_custom_title,
			};
		} catch {
			return undefined;
		}
	}

	private async setCurrentSurfaceTitle(title: string): Promise<boolean> {
		const surfaceId = process.env.CMUX_SURFACE_ID;
		if (!surfaceId) return false;
		return (await executeCmux(["rename-tab", "--surface", surfaceId, "--title", title])).ok;
	}

	private async clearCurrentSurfaceTitle(): Promise<boolean> {
		const surfaceId = process.env.CMUX_SURFACE_ID;
		if (!surfaceId) return false;
		return (await executeCmux(["tab-action", "--action", "clear-name", "--surface", surfaceId]))
			.ok;
	}

	private syncWorkspaceTitle(generation: number, cwd: string): Promise<void> {
		return this.project(async () => {
			const workspaceId = process.env.CMUX_WORKSPACE_ID;
			if (!workspaceId || generation !== this.state.generation) return;
			const [topLevel, originRemote] = await Promise.all([
				executeGit(cwd, ["rev-parse", "--show-toplevel"]),
				executeGit(cwd, ["remote", "get-url", "origin"]),
			]);
			if (!topLevel.ok || generation !== this.state.generation) return;
			const workspace = await this.currentWorkspaceMetadata(workspaceId);
			if (!workspace || generation !== this.state.generation) return;
			const target = gitWorkspaceRenameTarget(
				workspace.title,
				workspace.hasCustomTitle,
				topLevel.stdout,
				originRemote.ok ? repositoryNameFromRemote(originRemote.stdout) : undefined,
			);
			if (!target) return;
			await executeCmux(["workspace", "rename", workspaceId, "--title", target]);
		});
	}

	private recoverOrResetTitle(
		reason: SessionStartReason,
		generation: number,
		baseTitle: string,
	): Promise<void> {
		return this.project(async () => {
			if (generation !== this.state.generation) return;
			const recovered = await this.titleOwner.recoverOrReset(reason, baseTitle);
			if (generation !== this.state.generation) return;
			if (
				reason === "reload" &&
				recovered !== undefined &&
				recovered !== "idle" &&
				recovered !== "running"
			) {
				this.state = reduceFeedState(this.state, {
					type: "lifecycle_hydrated",
					generation,
					lifecycle: recovered,
				});
			}
		});
	}

	private markTitle(
		state: FeedState["lifecycle"],
		allowAcquire: boolean,
		generation: number,
		baseTitle: string,
	): void {
		void this.project(async () => {
			if (generation !== this.state.generation) return;
			await this.titleOwner.mark(state, allowAcquire, baseTitle);
		});
	}

	private rebaseTitle(generation: number, baseTitle: string): void {
		void this.project(async () => {
			if (generation !== this.state.generation) return;
			// Recovery is queued first. Read lifecycle at execution time so `/name`
			// and tree rebases retain a freshly hydrated terminal state.
			await this.titleOwner.mark(this.state.lifecycle, true, baseTitle);
		});
	}

	private markWorkingTitle(generation: number, baseTitle: string): void {
		this.markTitle("running", true, generation, baseTitle);
	}

	private markFinishedTitle(state: TerminalState, generation: number, baseTitle: string): void {
		this.markTitle(state, false, generation, baseTitle);
	}

	private clearOwnedTitle(): Promise<void> {
		return this.project(() => this.titleOwner.release());
	}

	private currentBranch(ctx: ExtensionContext): readonly unknown[] | undefined {
		try {
			return ctx.sessionManager.getBranch();
		} catch {
			return undefined;
		}
	}

	private handleSessionStart(
		reason: SessionStartReason,
		ctx: ExtensionContext,
		pi: ExtensionAPI,
	): void {
		this.cancelFinalProgressClear();
		const generation = this.state.generation + 1;
		this.state = reduceFeedState(this.state, { type: "session_started", generation, reason });
		this.lastRunMessages = [];
		this.messagesGeneration = 0;
		const cwd = ctx.cwd || process.cwd();
		const baseTitle = this.sessionTitle.reset(
			pi.getSessionName(),
			this.currentBranch(ctx) ?? [],
			cwd,
		);
		void this.recoverOrResetTitle(reason, generation, baseTitle);
		void this.clearProgress(generation);
		void this.syncWorkspaceTitle(generation, cwd);
		sendHook("session-start", ctx);
	}

	private handleSessionInfoChanged(name: string | undefined): void {
		const generation = this.state.generation;
		const baseTitle = this.sessionTitle.setExplicitName(name);
		this.rebaseTitle(generation, baseTitle);
	}

	private handleSessionTree(ctx: ExtensionContext): void {
		const branch = this.currentBranch(ctx);
		if (!branch) return;
		const generation = this.state.generation;
		const baseTitle = this.sessionTitle.setBranch(branch);
		this.rebaseTitle(generation, baseTitle);
	}

	private handleAgentStart(prompt: string, ctx: ExtensionContext): void {
		this.cancelFinalProgressClear();
		const baseTitle = this.sessionTitle.capturePrompt(prompt);
		const generation = this.state.generation + 1;
		this.state = reduceFeedState(this.state, {
			type: "run_started",
			generation,
			startedAt: Date.now(),
		});
		this.lastRunMessages = [];
		this.messagesGeneration = generation;
		this.setProgress(0.08, "Starting");
		sendHook("prompt-submit", ctx, { prompt });
		this.markWorkingTitle(generation, baseTitle);
		void this.syncWorkspaceTitle(generation, ctx.cwd || process.cwd());
	}

	private handleTurnStart(turnIndex: number): void {
		const generation = this.state.generation;
		this.state = reduceFeedState(this.state, { type: "turn_started", generation, turnIndex });
		if (this.state.lifecycle !== "running" || !this.state.run) return;
		this.setProgress(
			estimateProgress(this.state.run),
			turnIndex > 0 ? `Thinking · turn ${turnIndex + 1}` : "Thinking",
		);
	}

	private handleToolStart(toolCallId: string, toolName: string): void {
		const generation = this.state.generation;
		this.state = reduceFeedState(this.state, {
			type: "tool_started",
			generation,
			toolCallId,
			toolName,
		});
		if (this.state.lifecycle === "running" && this.state.run) {
			this.setProgress(estimateProgress(this.state.run), `Using ${toolName}`);
		}
	}

	private handleToolResult(event: ToolResultEvent): void {
		const generation = this.state.generation;
		let category: "read" | "changed" | "search" | "bash" | undefined;
		if (!event.isError) {
			if (isReadToolResult(event)) category = "read";
			else if (isEditToolResult(event) || isWriteToolResult(event)) category = "changed";
			else if (isGrepToolResult(event) || isFindToolResult(event)) category = "search";
			else if (isBashToolResult(event)) category = "bash";
		}
		this.state = reduceFeedState(this.state, {
			type: "tool_result",
			generation,
			toolCallId: event.toolCallId,
			category,
			path: getPathFromInput(event),
			error: event.isError ? summarizeToolError(event) : undefined,
		});
	}

	private handleToolEnd(toolCallId: string): void {
		const generation = this.state.generation;
		const before = Object.keys(this.state.activeTools).length;
		this.state = reduceFeedState(this.state, { type: "tool_ended", generation, toolCallId });
		if (
			before > 0 &&
			Object.keys(this.state.activeTools).length === 0 &&
			this.state.lifecycle === "running" &&
			this.state.run
		) {
			this.setProgress(estimateProgress(this.state.run), "Thinking");
		}
	}

	private handleAgentEnd(messages: readonly unknown[]): void {
		if (this.state.lifecycle !== "running") return;
		this.lastRunMessages = messages;
		this.messagesGeneration = this.state.generation;
	}

	private handleAgentSettled(ctx: ExtensionContext): void {
		if (this.state.lifecycle !== "running" || !this.state.run || !ctx.isIdle()) return;
		const generation = this.state.generation;
		const run = this.state.run;
		const durationMs = Date.now() - run.startedAt;
		const messages = this.messagesGeneration === generation ? this.lastRunMessages : [];
		const failure = summarizeRunFailure(messages, run.firstToolError);
		const summary =
			failure?.summary || summarizeSuccess(run, durationMs, this.notifyThresholdMs);
		const outcome: TerminalState = failure?.kind ?? "completed";
		this.state = reduceFeedState(this.state, {
			type: "agent_settled",
			generation,
			isIdle: true,
			outcome,
			summary,
		});
		if (this.state.lifecycle === "running") return;

		// Stop owns notification/unread/latestMessage. Sidebar attribution never
		// reads latestMessage, so a failed hook cannot turn stale text into truth.
		sendHook("stop", ctx, {
			last_assistant_message: summary,
			terminationReason: failure?.kind,
		});
		this.setProgress(1, this.finalProgressLabel(summary, failure));
		this.markFinishedTitle(outcome, generation, this.sessionTitle.title);
		this.scheduleFinalProgressClear(generation);
	}

	private finalProgressLabel(summary: string, failure?: RunFailure): string {
		if (!failure) return `Done · ${summary}`;
		return `${failure.kind === "error" ? "Error" : "Cancelled"} · ${summary}`;
	}

	private async handleSessionShutdown(reason: string, ctx: ExtensionContext): Promise<void> {
		this.cancelFinalProgressClear();
		const wasRunning = this.state.lifecycle === "running";
		if (reason !== "reload" || wasRunning) await this.clearOwnedTitle();
		await this.clearProgress();
		if (wasRunning) sendHook("stop", ctx, { terminationReason: reason });
	}
}

export default function (pi: ExtensionAPI) {
	if (!cmuxEnabled()) return;
	new CmuxFeedRuntime().register(pi);
}
