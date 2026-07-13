import {
	cleanLastNewline,
	getFiletypeFromFileName,
	getHighlighterOptions,
	getSharedHighlighter,
	parseDiffFromFile,
	parsePatchFiles,
	renderDiffWithHighlighter,
	type FileDiffMetadata,
	type SupportedLanguages,
} from "@pierre/diffs";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { access, readFile } from "node:fs/promises";
import { isAbsolute, relative, resolve, sep } from "node:path";
import type {
	DiffCell,
	DiffDocument,
	DiffLayout,
	DiffRow,
	DiffSourceRequest,
	HastNode,
	HighlightedDiff,
	HighlightSpan,
	PreparedDiffFile,
} from "./types.ts";

const PIERRE_THEME = "pierre-dark";
const MAX_PATCH_BYTES = 8 * 1024 * 1024;
const MAX_UNTRACKED_BYTES = 1024 * 1024;
const MAX_UNTRACKED_FILES = 100;

export async function parseDiffRequest(raw: string, cwd: string): Promise<DiffSourceRequest> {
	const tokens = tokenizeArguments(raw);
	let kind: DiffSourceRequest["kind"] = "working";
	let revision: string | undefined;

	if (["staged", "--staged", "--cached"].includes(tokens[0] ?? "")) {
		kind = "staged";
		tokens.shift();
	} else if (tokens[0] === "working") {
		tokens.shift();
	}

	const separatorIndex = tokens.indexOf("--");
	const positional = separatorIndex >= 0 ? tokens.slice(0, separatorIndex) : [...tokens];
	let paths = separatorIndex >= 0 ? tokens.slice(separatorIndex + 1) : [];

	if (kind === "staged") {
		if (positional.length > 0) {
			if (separatorIndex >= 0) {
				throw new Error("Unexpected argument before -- for staged diff");
			}
			paths = positional;
		}
	} else if (positional.length > 0) {
		if (separatorIndex < 0 && (await allPathsExist(cwd, positional))) {
			paths = positional;
		} else if (positional.length === 1) {
			kind = "revision";
			revision = positional[0];
		} else {
			throw new Error("Use /pdiff <revision> -- <paths...> when combining a ref and paths");
		}
	}

	if (paths.some((path) => path.length === 0)) {
		throw new Error("Diff paths cannot be empty");
	}

	return { kind, revision, paths };
}

export async function loadDiffDocument(
	pi: ExtensionAPI,
	cwd: string,
	request: DiffSourceRequest,
): Promise<DiffDocument> {
	const [rootResult, branchResult] = await Promise.all([
		pi.exec("git", ["rev-parse", "--show-toplevel"], { cwd, timeout: 5_000 }),
		pi.exec("git", ["branch", "--show-current"], { cwd, timeout: 5_000 }),
	]);

	if (rootResult.code !== 0) {
		throw new Error("Not inside a Git repository");
	}

	const root = rootResult.stdout.trim();
	const diffArgs = [
		"diff",
		"--no-color",
		"--no-ext-diff",
		"--src-prefix=a/",
		"--dst-prefix=b/",
		"--unified=3",
	];

	if (request.kind === "staged") diffArgs.push("--cached");
	if (request.kind === "revision" && request.revision) diffArgs.push(request.revision);
	if (request.paths.length > 0) diffArgs.push("--", ...request.paths);

	const diffResult = await pi.exec("git", diffArgs, { cwd, timeout: 15_000 });
	if (diffResult.code !== 0) {
		throw new Error(diffResult.stderr.trim() || `git diff exited with ${diffResult.code}`);
	}
	if (Buffer.byteLength(diffResult.stdout, "utf8") > MAX_PATCH_BYTES) {
		throw new Error("Diff exceeds the 8 MB viewer limit");
	}

	const notices: string[] = [];
	const metadata = parseTrackedPatch(diffResult.stdout);
	if (request.kind === "working") {
		metadata.push(
			...(await loadUntrackedFiles({
				cwd,
				notices,
				paths: request.paths,
				pi,
				root,
			})),
		);
	}

	const files = metadata.map(prepareFile);
	return {
		branch: branchResult.stdout.trim() || "detached",
		files,
		label: sourceLabel(request),
		notices,
		totalAdditions: files.reduce((sum, file) => sum + file.additions, 0),
		totalDeletions: files.reduce((sum, file) => sum + file.deletions, 0),
	};
}

export async function highlightFile(file: PreparedDiffFile): Promise<HighlightedDiff> {
	const language = file.metadata.lang ?? getFiletypeFromFileName(file.metadata.name);

	try {
		return await renderHighlighted(file.metadata, language);
	} catch {
		return renderHighlighted({ ...file.metadata, lang: "text" }, "text");
	}
}

export function buildRows(file: PreparedDiffFile, layout: DiffLayout): DiffRow[] {
	return layout === "split" ? buildSplitRows(file) : buildStackRows(file);
}

export function flattenHighlightedLine(
	node: HastNode | undefined,
	fallback: string | undefined,
): HighlightSpan[] {
	if (!node) return fallbackSpans(fallback);

	const spans: HighlightSpan[] = [];
	const visit = (current: HastNode | undefined, inherited: Omit<HighlightSpan, "text">) => {
		if (!current) return;
		if (current.type === "text") {
			appendSpan(spans, {
				text: normalizeCode(cleanLastNewline(current.value)),
				...inherited,
			});
			return;
		}

		const styles = parseStyles(current.properties?.style);
		const foreground = styles.get("--diffs-token-dark") ?? styles.get("color") ?? inherited.fg;
		const emphasis =
			inherited.emphasis || Object.hasOwn(current.properties ?? {}, "data-diff-span");

		for (const child of current.children ?? []) {
			visit(child, { fg: foreground, emphasis });
		}
	};

	visit(node, {});
	return spans.length > 0 ? spans : fallbackSpans(fallback);
}

function parseTrackedPatch(patch: string): FileDiffMetadata[] {
	if (!patch.trim()) return [];
	return parsePatchFiles(patch, "pdiff", true).flatMap((entry) => entry.files);
}

async function loadUntrackedFiles({
	cwd,
	notices,
	paths,
	pi,
	root,
}: {
	cwd: string;
	notices: string[];
	paths: string[];
	pi: ExtensionAPI;
	root: string;
}): Promise<FileDiffMetadata[]> {
	const args = ["ls-files", "--others", "--exclude-standard", "--full-name", "-z"];
	if (paths.length > 0) args.push("--", ...paths);
	const result = await pi.exec("git", args, { cwd, timeout: 10_000 });
	if (result.code !== 0 || !result.stdout) return [];

	const names = result.stdout.split("\0").filter(Boolean);
	if (names.length > MAX_UNTRACKED_FILES) {
		notices.push(`Showing the first ${MAX_UNTRACKED_FILES} untracked files`);
	}

	const files: FileDiffMetadata[] = [];
	for (const name of names.slice(0, MAX_UNTRACKED_FILES)) {
		const absolutePath = resolve(root, name);
		if (!isWithinRoot(root, absolutePath)) continue;

		try {
			const content = await readFile(absolutePath);
			if (content.byteLength > MAX_UNTRACKED_BYTES) {
				notices.push(`Skipped large untracked file: ${name}`);
				continue;
			}
			if (content.includes(0)) {
				notices.push(`Skipped binary untracked file: ${name}`);
				continue;
			}

			files.push(
				parseDiffFromFile(
					{ name, contents: "" },
					{ name, contents: content.toString("utf8") },
					undefined,
					true,
				),
			);
		} catch {
			notices.push(`Could not read untracked file: ${name}`);
		}
	}

	return files;
}

async function renderHighlighted(
	metadata: FileDiffMetadata,
	language: SupportedLanguages,
): Promise<HighlightedDiff> {
	const highlighter = await getSharedHighlighter(
		getHighlighterOptions(language, { theme: PIERRE_THEME }),
	);
	const rendered = renderDiffWithHighlighter(metadata, highlighter, {
		lineDiffType: "word-alt",
		maxLineDiffLength: 10_000,
		theme: PIERRE_THEME,
		tokenizeMaxLineLength: 1_000,
		useTokenTransformer: false,
	});

	return {
		additionLines: rendered.code.additionLines as Array<HastNode | undefined>,
		deletionLines: rendered.code.deletionLines as Array<HastNode | undefined>,
	};
}

function prepareFile(metadata: FileDiffMetadata): PreparedDiffFile {
	return {
		metadata,
		additions: metadata.hunks.reduce((sum, hunk) => sum + hunk.additionLines, 0),
		deletions: metadata.hunks.reduce((sum, hunk) => sum + hunk.deletionLines, 0),
	};
}

function buildSplitRows(file: PreparedDiffFile): DiffRow[] {
	const rows: DiffRow[] = [];
	const additions = file.highlighted?.additionLines ?? [];
	const deletions = file.highlighted?.deletionLines ?? [];

	for (const [hunkIndex, hunk] of file.metadata.hunks.entries()) {
		appendHunkPrefix(rows, hunkIndex, hunk.collapsedBefore, hunk.hunkSpecs);
		let deletionIndex = hunk.deletionLineIndex;
		let additionIndex = hunk.additionLineIndex;
		let deletionLine = hunk.deletionStart;
		let additionLine = hunk.additionStart;

		for (const content of hunk.hunkContent) {
			if (content.type === "context") {
				for (let offset = 0; offset < content.lines; offset += 1) {
					rows.push({
						type: "split-line",
						hunkIndex,
						left: makeCell({
							kind: "context",
							oldLine: deletionLine + offset,
							newLine: undefined,
							fallback: file.metadata.deletionLines[deletionIndex + offset],
							highlighted: deletions[deletionIndex + offset],
						}),
						right: makeCell({
							kind: "context",
							oldLine: undefined,
							newLine: additionLine + offset,
							fallback: file.metadata.additionLines[additionIndex + offset],
							highlighted: additions[additionIndex + offset],
						}),
					});
				}
				deletionIndex += content.lines;
				additionIndex += content.lines;
				deletionLine += content.lines;
				additionLine += content.lines;
				continue;
			}

			for (
				let offset = 0;
				offset < Math.max(content.deletions, content.additions);
				offset += 1
			) {
				rows.push({
					type: "split-line",
					hunkIndex,
					left:
						offset < content.deletions
							? makeCell({
									kind: "deletion",
									oldLine: deletionLine + offset,
									newLine: undefined,
									fallback: file.metadata.deletionLines[deletionIndex + offset],
									highlighted: deletions[deletionIndex + offset],
								})
							: emptyCell(),
					right:
						offset < content.additions
							? makeCell({
									kind: "addition",
									oldLine: undefined,
									newLine: additionLine + offset,
									fallback: file.metadata.additionLines[additionIndex + offset],
									highlighted: additions[additionIndex + offset],
								})
							: emptyCell(),
				});
			}

			deletionIndex += content.deletions;
			additionIndex += content.additions;
			deletionLine += content.deletions;
			additionLine += content.additions;
		}
	}

	return rows;
}

function buildStackRows(file: PreparedDiffFile): DiffRow[] {
	const rows: DiffRow[] = [];
	const additions = file.highlighted?.additionLines ?? [];
	const deletions = file.highlighted?.deletionLines ?? [];

	for (const [hunkIndex, hunk] of file.metadata.hunks.entries()) {
		appendHunkPrefix(rows, hunkIndex, hunk.collapsedBefore, hunk.hunkSpecs);
		let deletionIndex = hunk.deletionLineIndex;
		let additionIndex = hunk.additionLineIndex;
		let deletionLine = hunk.deletionStart;
		let additionLine = hunk.additionStart;

		for (const content of hunk.hunkContent) {
			if (content.type === "context") {
				for (let offset = 0; offset < content.lines; offset += 1) {
					rows.push({
						type: "stack-line",
						hunkIndex,
						cell: makeCell({
							kind: "context",
							oldLine: deletionLine + offset,
							newLine: additionLine + offset,
							fallback: file.metadata.additionLines[additionIndex + offset],
							highlighted: additions[additionIndex + offset],
						}),
					});
				}
				deletionIndex += content.lines;
				additionIndex += content.lines;
				deletionLine += content.lines;
				additionLine += content.lines;
				continue;
			}

			for (let offset = 0; offset < content.deletions; offset += 1) {
				rows.push({
					type: "stack-line",
					hunkIndex,
					cell: makeCell({
						kind: "deletion",
						oldLine: deletionLine + offset,
						newLine: undefined,
						fallback: file.metadata.deletionLines[deletionIndex + offset],
						highlighted: deletions[deletionIndex + offset],
					}),
				});
			}
			for (let offset = 0; offset < content.additions; offset += 1) {
				rows.push({
					type: "stack-line",
					hunkIndex,
					cell: makeCell({
						kind: "addition",
						oldLine: undefined,
						newLine: additionLine + offset,
						fallback: file.metadata.additionLines[additionIndex + offset],
						highlighted: additions[additionIndex + offset],
					}),
				});
			}

			deletionIndex += content.deletions;
			additionIndex += content.additions;
			deletionLine += content.deletions;
			additionLine += content.additions;
		}
	}

	return rows;
}

function appendHunkPrefix(
	rows: DiffRow[],
	hunkIndex: number,
	collapsed: number,
	specs: string | undefined,
) {
	if (collapsed > 0) {
		rows.push({
			type: "collapsed",
			hunkIndex,
			text: `${collapsed} unchanged ${collapsed === 1 ? "line" : "lines"}`,
		});
	}
	rows.push({
		type: "hunk-header",
		hunkIndex,
		text: cleanLastNewline(specs ?? "@@").trimEnd(),
	});
}

function makeCell({
	fallback,
	highlighted,
	kind,
	newLine,
	oldLine,
}: {
	fallback: string | undefined;
	highlighted: HastNode | undefined;
	kind: Exclude<DiffCell["kind"], "empty">;
	newLine: number | undefined;
	oldLine: number | undefined;
}): DiffCell {
	return {
		kind,
		oldLine,
		newLine,
		spans: flattenHighlightedLine(highlighted, fallback),
	};
}

function emptyCell(): DiffCell {
	return { kind: "empty", spans: [] };
}

function fallbackSpans(text: string | undefined): HighlightSpan[] {
	const normalized = normalizeCode(cleanLastNewline(text ?? ""));
	return normalized ? [{ text: normalized }] : [];
}

function appendSpan(target: HighlightSpan[], span: HighlightSpan) {
	if (!span.text) return;
	const previous = target.at(-1);
	if (previous && previous.fg === span.fg && previous.emphasis === span.emphasis) {
		previous.text += span.text;
		return;
	}
	target.push(span);
}

function parseStyles(value: unknown): Map<string, string> {
	const styles = new Map<string, string>();
	if (typeof value !== "string") return styles;
	for (const segment of value.split(";")) {
		const separator = segment.indexOf(":");
		if (separator <= 0) continue;
		styles.set(segment.slice(0, separator).trim(), segment.slice(separator + 1).trim());
	}
	return styles;
}

function normalizeCode(value: string): string {
	return value
		.replaceAll("\r", "")
		.replaceAll("\t", "    ")
		.replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f\u007f]/g, "�");
}

function sourceLabel(request: DiffSourceRequest): string {
	if (request.kind === "staged") return "staged";
	if (request.kind === "revision") return request.revision ?? "revision";
	return "working tree";
}

function tokenizeArguments(input: string): string[] {
	const tokens: string[] = [];
	let current = "";
	let quote: "'" | '"' | undefined;
	let escaping = false;

	for (const character of input.trim()) {
		if (escaping) {
			current += character;
			escaping = false;
			continue;
		}
		if (character === "\\" && quote !== "'") {
			escaping = true;
			continue;
		}
		if (quote) {
			if (character === quote) quote = undefined;
			else current += character;
			continue;
		}
		if (character === "'" || character === '"') {
			quote = character;
			continue;
		}
		if (/\s/.test(character)) {
			if (current) tokens.push(current);
			current = "";
			continue;
		}
		current += character;
	}

	if (escaping || quote) throw new Error("Unterminated quote or escape in /pdiff arguments");
	if (current) tokens.push(current);
	return tokens;
}

async function allPathsExist(cwd: string, paths: string[]): Promise<boolean> {
	const results = await Promise.all(
		paths.map(async (path) => {
			try {
				await access(isAbsolute(path) ? path : resolve(cwd, path));
				return true;
			} catch {
				return false;
			}
		}),
	);
	return results.every(Boolean);
}

function isWithinRoot(root: string, path: string): boolean {
	const rel = relative(root, path);
	return rel === "" || (!rel.startsWith(`..${sep}`) && rel !== ".." && !isAbsolute(rel));
}
