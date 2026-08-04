import * as path from "node:path";

const MAX_TITLE_CODE_POINTS = 48;
const RESERVED_TITLE_MARKERS = /[\u2062\u2063\u2064]/g;
const CONTROL_CHARACTERS = /[\u0000-\u001f\u007f-\u009f]/g;

function messageText(content: unknown): string | undefined {
	if (typeof content === "string") return content;
	if (!Array.isArray(content)) return undefined;
	const text = content
		.flatMap((block) => {
			if (!block || typeof block !== "object") return [];
			const typed = block as { type?: unknown; text?: unknown };
			return typed.type === "text" && typeof typed.text === "string" ? [typed.text] : [];
		})
		.join("\n");
	return text || undefined;
}

export function normalizeSessionTitle(value: unknown): string | undefined {
	if (typeof value !== "string") return undefined;
	const normalized = value
		.replace(RESERVED_TITLE_MARKERS, " ")
		.replace(CONTROL_CHARACTERS, " ")
		.replace(/\s+/g, " ")
		.trim();
	if (!normalized) return undefined;
	const codePoints = Array.from(normalized);
	if (codePoints.length <= MAX_TITLE_CODE_POINTS) return normalized;
	return `${codePoints.slice(0, MAX_TITLE_CODE_POINTS - 1).join("")}…`;
}

export function firstUserPrompt(entries: readonly unknown[]): string | undefined {
	for (const entry of entries) {
		if (!entry || typeof entry !== "object") continue;
		const typedEntry = entry as { type?: unknown; message?: unknown };
		if (
			typedEntry.type !== "message" ||
			!typedEntry.message ||
			typeof typedEntry.message !== "object"
		) {
			continue;
		}
		const message = typedEntry.message as { role?: unknown; content?: unknown };
		if (message.role !== "user") continue;
		const title = normalizeSessionTitle(messageText(message.content));
		if (title) return title;
	}
	return undefined;
}

function fallbackTitle(cwd: string): string {
	const resolved = path.resolve(cwd || process.cwd());
	const directory = path.basename(resolved) || path.parse(resolved).root || resolved;
	return normalizeSessionTitle(`pi · ${directory}`) ?? "pi";
}

export class SessionTitleResolver {
	private explicitName: string | undefined;
	private promptTitle: string | undefined;
	private fallback = fallbackTitle(process.cwd());

	reset(explicitName: unknown, branch: readonly unknown[], cwd: string): string {
		this.explicitName = normalizeSessionTitle(explicitName);
		this.promptTitle = firstUserPrompt(branch);
		this.fallback = fallbackTitle(cwd);
		return this.title;
	}

	setExplicitName(name: unknown): string {
		this.explicitName = normalizeSessionTitle(name);
		return this.title;
	}

	capturePrompt(prompt: unknown): string {
		if (!this.promptTitle) this.promptTitle = normalizeSessionTitle(prompt);
		return this.title;
	}

	setBranch(branch: readonly unknown[]): string {
		this.promptTitle = firstUserPrompt(branch);
		return this.title;
	}

	get title(): string {
		return this.explicitName ?? this.promptTitle ?? this.fallback;
	}
}
