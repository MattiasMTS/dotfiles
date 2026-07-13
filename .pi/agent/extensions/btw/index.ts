import { complete, type UserMessage } from "@earendil-works/pi-ai/compat";
import {
	convertToLlm,
	copyToClipboard,
	getMarkdownTheme,
	sessionEntryToContextMessages,
	type ExtensionAPI,
	type ExtensionCommandContext,
	type ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Container, Key, Loader, Markdown, matchesKey, Text } from "@earendil-works/pi-tui";

const SYSTEM_PROMPT = `You are answering a Claude Code-style /btw side question.

Behavior:
- Answer the user's side question using the supplied session context.
- Do not ask to run tools. Do not suggest changing the active plan unless directly asked.
- Be concise, concrete, and useful.
- If the answer is uncertain or not in context, say so directly.
- Prefer short bullets. No preamble.`;

const MAX_TRANSCRIPT_CHARS = 40_000;
const MAX_PART_CHARS = 4_000;
const THREAD_MESSAGE_TYPE = "btw-thread";

type BtwPanelStatus = "answering" | "done" | "error";

interface BtwPanel {
	id: string;
	question: string;
	status: BtwPanelStatus;
	answer?: string;
	notice?: string;
	startedAt: number;
	transcript: string;
	sourceEntryId?: string;
	scrollOffset: number;
	maxScrollOffset: number;
	controller: AbortController;
	commandCtx: ExtensionCommandContext;
}

interface BtwThreadDetails {
	question: string;
	answer: string;
	status: Exclude<BtwPanelStatus, "answering">;
}

let currentPanel: BtwPanel | undefined;
let lastCtx: ExtensionContext | undefined;
let unsubscribeTerminalInput: (() => void) | undefined;

export default function (pi: ExtensionAPI) {
	pi.on("session_start", (_event, ctx) => {
		lastCtx = ctx;
		unsubscribeTerminalInput?.();
		unsubscribeTerminalInput = ctx.ui.onTerminalInput((data) => handleBtwInput(pi, data));
	});

	pi.on("session_shutdown", () => {
		currentPanel?.controller.abort();
		currentPanel = undefined;
		lastCtx = undefined;
		unsubscribeTerminalInput?.();
		unsubscribeTerminalInput = undefined;
	});

	pi.registerMessageRenderer(THREAD_MESSAGE_TYPE, (message, _options, theme) => {
		const details = message.details as BtwThreadDetails | undefined;
		const question = details?.question ?? "Side question";
		const answer = details?.answer ?? (extractText(message.content).trim() || "No answer.");

		const container = new Container();
		container.addChild(
			new Text(
				`  ${theme.fg("accent", theme.bold("/btw fork"))} ${theme.fg("muted", question)}`,
				0,
				0,
			),
		);
		container.addChild(new Markdown(answer, 2, 1, getMarkdownTheme()));
		return container;
	});

	pi.registerCommand("btw", {
		description: "Ask a temporary side question without adding it to the main conversation",
		handler: async (args, ctx) => {
			lastCtx = ctx;
			let question = args.trim();

			if (!question && ctx.mode === "tui") {
				question = (await ctx.ui.input("btw", "side question"))?.trim() ?? "";
			}

			if (!question) {
				ctx.ui.notify("Usage: /btw <side question>", "error");
				return;
			}

			if (!ctx.model) {
				ctx.ui.notify("No model selected", "error");
				return;
			}

			if (ctx.mode !== "tui") {
				ctx.ui.notify("/btw currently requires interactive mode", "error");
				return;
			}

			currentPanel?.controller.abort();
			const panel: BtwPanel = {
				id: `${Date.now()}-${Math.random().toString(16).slice(2)}`,
				question,
				status: "answering",
				startedAt: Date.now(),
				transcript: buildTranscript(ctx),
				sourceEntryId: ctx.sessionManager.getLeafId() ?? undefined,
				scrollOffset: 0,
				maxScrollOffset: 0,
				controller: new AbortController(),
				commandCtx: ctx,
			};

			currentPanel = panel;
			updateBtwWidget(ctx);
			void runBtwTask(panel);
		},
	});

	pi.registerCommand("btw-clear", {
		description: "Close the active /btw side question",
		handler: async () => {
			dismissBtwPanel();
		},
	});
}

async function runBtwTask(panel: BtwPanel) {
	const { commandCtx: ctx } = panel;
	const model = ctx.model;
	if (!model) {
		finishBtwPanel(panel, "error", "btw error: No model selected");
		return;
	}

	try {
		const auth = await ctx.modelRegistry.getApiKeyAndHeaders(model);
		if (!auth.ok || !auth.apiKey) {
			throw new Error(auth.ok ? `No API key for ${model.provider}` : auth.error);
		}

		const userMessage: UserMessage = {
			role: "user",
			content: [
				{
					type: "text",
					text: `Current working directory: ${ctx.cwd}\n\nRecent session context:\n${panel.transcript}\n\nSide question:\n${panel.question}`,
				},
			],
			timestamp: Date.now(),
		};

		const response = await complete(
			model,
			{ systemPrompt: SYSTEM_PROMPT, messages: [userMessage] },
			{
				apiKey: auth.apiKey,
				headers: auth.headers,
				env: auth.env,
				signal: panel.controller.signal,
			},
		);

		if (response.stopReason === "aborted") return;

		const answer = response.content
			.flatMap((part) => (part.type === "text" ? [part.text] : []))
			.join("\n")
			.trim();

		finishBtwPanel(panel, "done", answer || "No answer.");
	} catch (error) {
		if (panel.controller.signal.aborted) return;
		finishBtwPanel(
			panel,
			"error",
			`btw error: ${error instanceof Error ? error.message : String(error)}`,
		);
	}
}

function finishBtwPanel(
	panel: BtwPanel,
	status: Exclude<BtwPanelStatus, "answering">,
	answer: string,
) {
	if (currentPanel?.id !== panel.id) return;
	panel.status = status;
	panel.answer = answer;
	panel.scrollOffset = 0;
	panel.maxScrollOffset = 0;
	if (lastCtx) updateBtwWidget(lastCtx);
}

function dismissBtwPanel() {
	const panel = currentPanel;
	currentPanel = undefined;
	if (panel?.status === "answering") panel.controller.abort();
	lastCtx?.ui.setWidget("btw", undefined);
}

function handleBtwInput(pi: ExtensionAPI, data: string): { consume?: boolean } | undefined {
	const panel = currentPanel;
	if (!panel) return undefined;

	if (matchesKey(data, Key.escape) || matchesKey(data, Key.ctrl("c"))) {
		dismissBtwPanel();
		return { consume: true };
	}

	// Keep the normal editor usable while the side answer is still running.
	if (panel.status === "answering") return undefined;

	if (matchesKey(data, Key.up)) {
		panel.scrollOffset = Math.max(0, panel.scrollOffset - 1);
		panel.notice = undefined;
		requestBtwRender();
		return { consume: true };
	}

	if (matchesKey(data, Key.down)) {
		panel.scrollOffset = Math.min(panel.maxScrollOffset, panel.scrollOffset + 1);
		panel.notice = undefined;
		requestBtwRender();
		return { consume: true };
	}

	if (data === "c" && panel.answer) {
		const panelId = panel.id;
		void copyToClipboard(panel.answer)
			.then(() => {
				if (currentPanel?.id !== panelId) return;
				currentPanel.notice = "Copied answer";
				requestBtwRender();
			})
			.catch((error) => {
				if (currentPanel?.id !== panelId) return;
				currentPanel.notice = `Copy failed: ${error instanceof Error ? error.message : String(error)}`;
				requestBtwRender();
			});
		return { consume: true };
	}

	if (data === "f" && panel.answer) {
		if (!panel.sourceEntryId) {
			panel.notice = "Nothing to fork yet";
			requestBtwRender();
			return { consume: true };
		}

		const forkInput = {
			ctx: panel.commandCtx,
			sourceEntryId: panel.sourceEntryId,
			question: panel.question,
			answer: panel.answer,
			status: panel.status,
		};
		dismissBtwPanel();
		void forkBtwExchange(forkInput);
		return { consume: true };
	}

	// Once answered, the temporary panel owns input until dismissed.
	return { consume: true };
}

function updateBtwWidget(ctx: ExtensionContext) {
	lastCtx = ctx;
	if (!currentPanel) {
		ctx.ui.setWidget("btw", undefined);
		return;
	}

	ctx.ui.setWidget(
		"btw",
		(tui, theme) => {
			const loader =
				currentPanel?.status === "answering"
					? new Loader(
							tui,
							(spinner) => theme.fg("accent", spinner),
							(message) => theme.fg("muted", message),
							"Answering…",
						)
					: undefined;

			return {
				render: (width) => {
					const panel = currentPanel;
					if (!panel || width <= 0) return [];

					const lines: string[] = [];
					const question = panel.question.replace(/\s+/g, " ");
					const header = `  ${theme.fg("warning", theme.bold("/btw"))} ${theme.fg("muted", question)}`;
					lines.push(...new Text(header, 0, 0).render(width));

					if (panel.status === "answering") {
						if (loader) lines.push(...loader.render(width));
						lines.push("");
						lines.push(
							...new Text(theme.fg("dim", "  Esc/Ctrl+C to close"), 0, 0).render(
								width,
							),
						);
						return lines;
					}

					lines.push("");
					const answer = panel.answer ?? "No answer.";
					const answerLines = new Markdown(answer, 4, 0, getMarkdownTheme()).render(
						width,
					);
					const answerHeight = Math.max(1, Math.floor(tui.terminal.rows * 0.45));
					panel.maxScrollOffset = Math.max(0, answerLines.length - answerHeight);
					panel.scrollOffset = Math.min(panel.scrollOffset, panel.maxScrollOffset);
					lines.push(
						...answerLines.slice(panel.scrollOffset, panel.scrollOffset + answerHeight),
					);
					lines.push("");

					const help =
						panel.notice ??
						"  ↑/↓ to scroll · c to copy · f to fork · Esc/Ctrl+C to close";
					lines.push(...new Text(theme.fg("dim", help), 0, 0).render(width));
					return lines;
				},
				invalidate: () => loader?.invalidate(),
				dispose: () => loader?.stop(),
			};
		},
		{ placement: "aboveEditor" },
	);
}

function requestBtwRender() {
	if (lastCtx) updateBtwWidget(lastCtx);
}

async function forkBtwExchange(input: {
	ctx: ExtensionCommandContext;
	sourceEntryId: string;
	question: string;
	answer: string;
	status: Exclude<BtwPanelStatus, "answering">;
}) {
	try {
		await input.ctx.waitForIdle();
		const result = await input.ctx.fork(input.sourceEntryId, {
			position: "at",
			withSession: async (newCtx) => {
				const details: BtwThreadDetails = {
					question: input.question,
					answer: input.answer,
					status: input.status,
				};
				await newCtx.sendMessage(
					{
						customType: THREAD_MESSAGE_TYPE,
						content: `Side question:\n${input.question}\n\nSide answer:\n${input.answer}`,
						display: true,
						details,
					},
					{ triggerTurn: false },
				);
			},
		});

		if (result.cancelled) input.ctx.ui.notify("btw fork cancelled", "warning");
	} catch (error) {
		try {
			input.ctx.ui.notify(
				`btw fork error: ${error instanceof Error ? error.message : String(error)}`,
				"error",
			);
		} catch {
			// Context can become stale after session replacement.
		}
	}
}

function buildTranscript(ctx: ExtensionCommandContext): string {
	const messages = convertToLlm(
		ctx.sessionManager
			.buildContextEntries()
			.flatMap((entry) => sessionEntryToContextMessages(entry)),
	);
	const chunks: string[] = [];

	for (const message of messages) {
		const label =
			message.role === "toolResult" ? `tool:${message.toolName ?? "unknown"}` : message.role;
		const text = extractText(message.content).trim();
		if (!text) continue;
		chunks.push(`## ${label}\n${truncate(text, MAX_PART_CHARS)}`);
	}

	const transcript = chunks.join("\n\n");
	if (transcript.length <= MAX_TRANSCRIPT_CHARS) return transcript || "(no prior context)";
	return `[earlier context omitted]\n\n${transcript.slice(-MAX_TRANSCRIPT_CHARS)}`;
}

function extractText(content: unknown): string {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return "";

	return content
		.flatMap((part) => {
			if (!part || typeof part !== "object") return [];
			const p = part as Record<string, unknown>;
			if (p.type === "text" && typeof p.text === "string") return [p.text];
			if (p.type === "toolCall") {
				const name = typeof p.name === "string" ? p.name : "tool";
				return [`[tool call: ${name}]`];
			}
			if (p.type === "image") return ["[image]"];
			return [];
		})
		.join("\n");
}

function truncate(text: string, maxChars: number): string {
	if (text.length <= maxChars) return text;
	return `${text.slice(0, maxChars)}\n[truncated ${text.length - maxChars} chars]`;
}
