export const OWNED_TITLE_SEPARATOR = "\u2063";
export const OWNED_TITLE_AUTOMATIC = "\u2064";
export const OWNED_TITLE_MANUAL = "\u2062";

export const LIFECYCLE_STATES = ["idle", "running", "completed", "error", "cancelled"] as const;
export type LifecycleState = (typeof LIFECYCLE_STATES)[number];
export type TerminalState = Exclude<LifecycleState, "idle" | "running">;
export type SessionStartReason = "startup" | "reload" | "new" | "resume" | "fork";

const TITLE_GLYPHS: Record<LifecycleState, string> = {
	idle: "○",
	running: "⠋",
	completed: "✓",
	error: "!",
	cancelled: "×",
};

export interface OwnedTitle {
	state: LifecycleState;
	baseTitle: string;
	preservesManualTitle: boolean;
}

export function parseOwnedTitle(title: string): OwnedTitle | undefined {
	for (const state of LIFECYCLE_STATES) {
		const prefix = `${TITLE_GLYPHS[state]}${OWNED_TITLE_SEPARATOR}`;
		if (!title.startsWith(prefix)) continue;
		const remainder = title.slice(prefix.length);
		const automaticPrefix = `${OWNED_TITLE_AUTOMATIC}${OWNED_TITLE_SEPARATOR}`;
		const manualPrefix = `${OWNED_TITLE_MANUAL}${OWNED_TITLE_SEPARATOR}`;
		if (remainder.startsWith(automaticPrefix)) {
			return {
				state,
				baseTitle: remainder.slice(automaticPrefix.length),
				preservesManualTitle: false,
			};
		}
		if (remainder.startsWith(manualPrefix)) {
			return {
				state,
				baseTitle: remainder.slice(manualPrefix.length),
				preservesManualTitle: true,
			};
		}

		// Legacy protocol: one separator meant automatic, two meant manual.
		const preservesManualTitle = remainder.startsWith(OWNED_TITLE_SEPARATOR);
		return {
			state,
			baseTitle: preservesManualTitle
				? remainder.slice(OWNED_TITLE_SEPARATOR.length)
				: remainder,
			preservesManualTitle,
		};
	}
	return undefined;
}

export function formatOwnedTitle(
	state: LifecycleState,
	baseTitle: string,
	preservesManualTitle: boolean,
): string {
	const discriminator = preservesManualTitle ? OWNED_TITLE_MANUAL : OWNED_TITLE_AUTOMATIC;
	return `${TITLE_GLYPHS[state]}${OWNED_TITLE_SEPARATOR}${discriminator}${OWNED_TITLE_SEPARATOR}${baseTitle}`;
}

export function stripOwnedTitle(title: string): string {
	return parseOwnedTitle(title)?.baseTitle ?? title;
}

export interface RunMetrics {
	startedAt: number;
	readFiles: ReadonlySet<string>;
	changedFiles: ReadonlySet<string>;
	searchCount: number;
	bashCount: number;
	toolCount: number;
	turnCount: number;
	firstToolError?: string;
}

export interface FeedState {
	generation: number;
	lifecycle: LifecycleState;
	run?: RunMetrics;
	activeTools: Readonly<Record<string, string>>;
	terminalSummary?: string;
}

export type FeedEvent =
	| {
			type: "session_started";
			generation: number;
			reason: SessionStartReason;
	  }
	| { type: "lifecycle_hydrated"; generation: number; lifecycle: TerminalState }
	| { type: "run_started"; generation: number; startedAt: number }
	| { type: "turn_started"; generation: number; turnIndex: number }
	| {
			type: "tool_started";
			generation: number;
			toolCallId: string;
			toolName: string;
	  }
	| {
			type: "tool_result";
			generation: number;
			toolCallId: string;
			category?: "read" | "changed" | "search" | "bash";
			path?: string;
			error?: string;
	  }
	| { type: "tool_ended"; generation: number; toolCallId: string }
	| {
			type: "agent_settled";
			generation: number;
			isIdle: boolean;
			outcome: TerminalState;
			summary: string;
	  }
	| { type: "progress_cleared"; generation: number };

export function createFeedState(): FeedState {
	return { generation: 0, lifecycle: "idle", activeTools: {} };
}

function createRunMetrics(startedAt: number): RunMetrics {
	return {
		startedAt,
		readFiles: new Set(),
		changedFiles: new Set(),
		searchCount: 0,
		bashCount: 0,
		toolCount: 0,
		turnCount: 0,
	};
}

function withRun(state: FeedState, update: (run: RunMetrics) => RunMetrics): FeedState {
	if (state.lifecycle !== "running" || !state.run) return state;
	return { ...state, run: update(state.run) };
}

export function reduceFeedState(state: FeedState, event: FeedEvent): FeedState {
	if (event.type === "session_started") {
		if (event.generation <= state.generation) return state;
		if (
			event.reason === "reload" &&
			(state.lifecycle === "completed" ||
				state.lifecycle === "error" ||
				state.lifecycle === "cancelled")
		) {
			return { ...state, generation: event.generation, activeTools: {} };
		}
		return { generation: event.generation, lifecycle: "idle", activeTools: {} };
	}

	if (event.type === "run_started") {
		if (event.generation <= state.generation) return state;
		return {
			generation: event.generation,
			lifecycle: "running",
			run: createRunMetrics(event.startedAt),
			activeTools: {},
		};
	}

	if (event.generation !== state.generation) return state;
	if (event.type === "lifecycle_hydrated") {
		if (state.lifecycle === "running") return state;
		return {
			...state,
			lifecycle: event.lifecycle,
			activeTools: {},
			terminalSummary:
				state.lifecycle === event.lifecycle ? state.terminalSummary : undefined,
		};
	}
	if (event.type === "progress_cleared") return state;
	if (state.lifecycle !== "running") return state;

	switch (event.type) {
		case "turn_started":
			return withRun(state, (run) => ({
				...run,
				turnCount: Math.max(run.turnCount, event.turnIndex + 1),
			}));
		case "tool_started":
			return {
				...state,
				activeTools: { ...state.activeTools, [event.toolCallId]: event.toolName },
			};
		case "tool_result":
			return withRun(state, (run) => {
				const readFiles = new Set(run.readFiles);
				const changedFiles = new Set(run.changedFiles);
				if (event.category === "read" && event.path) readFiles.add(event.path);
				if (event.category === "changed" && event.path) changedFiles.add(event.path);
				return {
					...run,
					readFiles,
					changedFiles,
					searchCount: run.searchCount + (event.category === "search" ? 1 : 0),
					bashCount: run.bashCount + (event.category === "bash" ? 1 : 0),
					toolCount: run.toolCount + 1,
					firstToolError: run.firstToolError ?? event.error,
				};
			});
		case "tool_ended": {
			if (!(event.toolCallId in state.activeTools)) return state;
			const activeTools = { ...state.activeTools };
			delete activeTools[event.toolCallId];
			return { ...state, activeTools };
		}
		case "agent_settled":
			if (!event.isIdle) return state;
			return {
				...state,
				lifecycle: event.outcome,
				activeTools: {},
				terminalSummary: event.summary,
			};
		default:
			return state;
	}
}
