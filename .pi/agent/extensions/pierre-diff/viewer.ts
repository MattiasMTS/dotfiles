import type { Theme } from "@earendil-works/pi-coding-agent";
import { Key, matchesKey, truncateToWidth, type TUI, visibleWidth } from "@earendil-works/pi-tui";
import { buildRows, highlightFile } from "./engine.ts";
import type {
	DiffCell,
	DiffDocument,
	DiffLayout,
	DiffRow,
	HighlightSpan,
	PreparedDiffFile,
} from "./types.ts";

const RESET = "\x1b[0m";
const MIN_VIEWER_HEIGHT = 10;
const SPLIT_VIEW_MIN_WIDTH = 82;

const COLORS = {
	addition: "#5ecc71",
	additionBg: "#122817",
	additionEmphasisBg: "#214b2c",
	additionGutterBg: "#183820",
	contextBg: "#131313",
	contextGutterBg: "#090909",
	deletion: "#ff6762",
	deletionBg: "#331415",
	deletionEmphasisBg: "#572426",
	deletionGutterBg: "#461b1d",
	emptyBg: "#111111",
	number: "#858585",
} as const;

interface ViewerCallbacks {
	done: () => void;
	refresh: () => Promise<DiffDocument>;
}

export class PierreDiffViewer {
	private activeLayout: DiffLayout = "stack";
	private readonly callbacks: ViewerCallbacks;
	private disposed = false;
	private document: DiffDocument;
	private fileIndex = 0;
	private hunkIndex = 0;
	private layoutOverride?: DiffLayout;
	private maxScrollOffset = 0;
	private notice?: string;
	private refreshing = false;
	private rowsCache?: { file: PreparedDiffFile; layout: DiffLayout; rows: DiffRow[] };
	private scrollOffset = 0;
	private readonly theme: Theme;
	private readonly tui: TUI;

	constructor(tui: TUI, theme: Theme, document: DiffDocument, callbacks: ViewerCallbacks) {
		this.callbacks = callbacks;
		this.document = document;
		this.theme = theme;
		this.tui = tui;
		this.ensureHighlighted();
	}

	handleInput(data: string): void {
		if (this.handleExitInput(data)) return;
		if (this.handleScrollInput(data)) return;
		if (this.handleNavigationInput(data)) return;
		this.handleViewInput(data);
	}

	render(width: number): string[] {
		if (width <= 0) return [];
		const frameWidth = Math.max(1, width);
		const bodyHeight = this.bodyHeight();
		const diffWidth = Math.max(1, frameWidth - 2);
		const layout = this.resolveLayout(diffWidth);
		this.activeLayout = layout;
		const rows = this.currentRows(layout);
		this.maxScrollOffset = Math.max(0, rows.length - bodyHeight);
		this.scrollOffset = clamp(this.scrollOffset, 0, this.maxScrollOffset);

		const lines = [
			this.renderTopBorder(frameWidth),
			this.renderFrameLine(this.renderFileHeader(diffWidth), frameWidth),
			this.renderSeparator(frameWidth),
			...this.renderBody(rows, bodyHeight, diffWidth, layout).map((row) =>
				this.renderFrameLine(row, frameWidth),
			),
			this.renderSeparator(frameWidth),
			this.renderFrameLine(this.renderFooter(layout, diffWidth), frameWidth),
			this.theme.fg("border", `╰${"─".repeat(Math.max(0, frameWidth - 2))}╯`),
		];
		return lines.map((line) => fitAnsi(line, frameWidth));
	}

	private handleExitInput(data: string): boolean {
		if (!matchesKey(data, Key.escape) && !matchesKey(data, Key.ctrl("c")) && data !== "q") {
			return false;
		}
		this.callbacks.done();
		return true;
	}

	private handleScrollInput(data: string): boolean {
		if (matchesKey(data, Key.down) || data === "j") {
			this.scrollBy(1);
			return true;
		}
		if (matchesKey(data, Key.up) || data === "k") {
			this.scrollBy(-1);
			return true;
		}
		if (matchesKey(data, Key.ctrl("d"))) {
			this.scrollBy(Math.max(1, Math.floor(this.bodyHeight() / 2)));
			return true;
		}
		if (matchesKey(data, Key.ctrl("u"))) {
			this.scrollBy(-Math.max(1, Math.floor(this.bodyHeight() / 2)));
			return true;
		}
		if (data === "g") {
			this.scrollOffset = 0;
			this.syncHunkToScroll();
			this.requestRender();
			return true;
		}
		if (data === "G") {
			this.scrollOffset = this.maxScrollOffset;
			this.syncHunkToScroll();
			this.requestRender();
			return true;
		}
		return false;
	}

	private handleNavigationInput(data: string): boolean {
		if (data === "n") this.moveHunk(1);
		else if (data === "N") this.moveHunk(-1);
		else if (matchesKey(data, Key.shift("tab"))) this.moveFile(-1);
		else if (matchesKey(data, Key.tab)) this.moveFile(1);
		else return false;
		return true;
	}

	private handleViewInput(data: string): void {
		if (data === "s") {
			this.layoutOverride = this.activeLayout === "split" ? "stack" : "split";
			this.resetRows();
			this.requestRender();
		} else if (data === "r") this.reload();
	}

	invalidate(): void {
		this.resetRows();
	}

	dispose(): void {
		this.disposed = true;
	}

	private bodyHeight(): number {
		const available = Math.max(MIN_VIEWER_HEIGHT, Math.floor(this.tui.terminal.rows * 0.82));
		return Math.max(4, available - 6);
	}

	private resolveLayout(diffWidth: number): DiffLayout {
		if (this.layoutOverride === "split" && diffWidth < 72) return "stack";
		return this.layoutOverride ?? (diffWidth >= SPLIT_VIEW_MIN_WIDTH ? "split" : "stack");
	}

	private selectedFile(): PreparedDiffFile | undefined {
		return this.document.files[this.fileIndex];
	}

	private currentRows(layout: DiffLayout): DiffRow[] {
		const file = this.selectedFile();
		if (!file) return [];
		if (this.rowsCache?.file === file && this.rowsCache.layout === layout) {
			return this.rowsCache.rows;
		}
		const rows = buildRows(file, layout).filter((row) => row.type !== "hunk-header");
		this.rowsCache = { file, layout, rows };
		return rows;
	}

	private resetRows(): void {
		this.rowsCache = undefined;
	}

	private renderTopBorder(width: number): string {
		return this.theme.fg("border", `╭${"─".repeat(Math.max(0, width - 2))}╮`);
	}

	private renderFileHeader(width: number): string {
		const file = this.selectedFile();
		if (!file) return this.theme.fg("muted", " No changes");

		const progress = `${this.fileIndex + 1}/${this.document.files.length}`;
		const highlighting = file.highlightPending ? " · highlighting…" : "";
		const right = `${this.theme.fg(statusColor(file), statusLetter(file))} ${this.theme.fg("success", `+${file.additions}`)} ${this.theme.fg("error", `−${file.deletions}`)} ${this.theme.fg("muted", `· ${progress}${highlighting}`)} `;
		const nameWidth = Math.max(1, width - visibleWidth(right) - 3);
		const name = truncateToWidth(fileDisplayName(file), nameWidth, "…");
		const left = ` ${this.theme.fg("text", this.theme.bold(name))}`;
		const gap = " ".repeat(Math.max(1, width - visibleWidth(left) - visibleWidth(right)));
		return `${left}${gap}${right}`;
	}

	private renderBody(
		rows: DiffRow[],
		height: number,
		width: number,
		layout: DiffLayout,
	): string[] {
		if (this.document.files.length === 0) {
			return [
				this.theme.fg("muted", " No differences found"),
				...Array.from({ length: height - 1 }, () => ""),
			];
		}
		if (rows.length === 0) {
			return [
				this.theme.fg("muted", " Binary, empty, or mode-only change"),
				...Array.from({ length: height - 1 }, () => ""),
			];
		}

		const visible = rows.slice(this.scrollOffset, this.scrollOffset + height);
		const lines = visible.map((row) => this.renderDiffRow(row, width, layout));
		while (lines.length < height) lines.push("");
		return lines;
	}

	private renderDiffRow(row: DiffRow, width: number, layout: DiffLayout): string {
		if (row.type === "collapsed") {
			const label = ` ${row.text} `;
			const remaining = Math.max(0, width - visibleWidth(label) - 2);
			const left = Math.floor(remaining / 2);
			const right = remaining - left;
			return this.theme.fg("dim", `${"─".repeat(left)}${label}${"─".repeat(right)}`);
		}
		if (row.type === "hunk-header") {
			const marker = row.hunkIndex === this.hunkIndex ? this.theme.fg("accent", "▶") : " ";
			return fitAnsi(`${marker} ${this.theme.fg("muted", safeText(row.text))}`, width);
		}
		if (layout === "split" && row.type === "split-line") {
			const separatorWidth = 1;
			const leftWidth = Math.floor((width - separatorWidth) / 2);
			const rightWidth = Math.max(1, width - separatorWidth - leftWidth);
			return `${this.renderSplitCell(row.left, leftWidth)}${this.theme.fg("borderMuted", "│")}${this.renderSplitCell(row.right, rightWidth)}`;
		}
		if (row.type === "stack-line") return this.renderStackCell(row.cell, width);
		return "";
	}

	private renderSplitCell(cell: DiffCell, width: number): string {
		if (cell.kind === "empty") return paintPadding(width, COLORS.emptyBg);
		const digits = this.lineNumberDigits();
		const line = cell.oldLine ?? cell.newLine;
		const number = line === undefined ? " ".repeat(digits) : String(line).padStart(digits);
		const palette = cellPalette(cell.kind);
		const gutter = colorText(
			`${diffRail(cell.kind)} ${number} `,
			palette.gutterFg,
			palette.gutterBg,
		);
		const codeWidth = Math.max(0, width - visibleWidth(gutter));
		const code = renderSpans(cell.spans, palette.rowBg, palette.emphasisBg);
		return `${gutter}${fitAnsiWithBackground(code, codeWidth, palette.rowBg)}`;
	}

	private renderStackCell(cell: DiffCell, width: number): string {
		const digits = this.lineNumberDigits();
		const oldLine =
			cell.oldLine === undefined ? " ".repeat(digits) : String(cell.oldLine).padStart(digits);
		const newLine =
			cell.newLine === undefined ? " ".repeat(digits) : String(cell.newLine).padStart(digits);
		const palette = cellPalette(cell.kind);
		const gutter = colorText(
			`${diffRail(cell.kind)} ${oldLine} ${newLine} `,
			palette.gutterFg,
			palette.gutterBg,
		);
		const codeWidth = Math.max(0, width - visibleWidth(gutter));
		const code = renderSpans(cell.spans, palette.rowBg, palette.emphasisBg);
		return `${gutter}${fitAnsiWithBackground(code, codeWidth, palette.rowBg)}`;
	}

	private lineNumberDigits(): number {
		const file = this.selectedFile();
		if (!file) return 1;
		let maximum = 1;
		for (const hunk of file.metadata.hunks) {
			maximum = Math.max(
				maximum,
				hunk.additionStart + hunk.additionCount,
				hunk.deletionStart + hunk.deletionCount,
			);
		}
		return String(maximum).length;
	}

	private renderFooter(layout: DiffLayout, width: number): string {
		const file = this.selectedFile();
		const progress = `${Math.min(this.fileIndex + 1, this.document.files.length)}/${this.document.files.length}`;
		const hunkCount = file?.metadata.hunks.length ?? 0;
		const hunk = `${Math.min(this.hunkIndex + 1, hunkCount)}/${hunkCount}`;
		const status = this.refreshing
			? "refreshing…"
			: (this.notice ?? this.document.notices.at(-1) ?? "");
		const controls = `tab/⇧tab file · n/N hunk · s ${layout} · r · q`;

		if (width < 96) {
			const compact = ` ${status ? `${status} · ` : ""}${progress} · hunk ${hunk} · ${controls}`;
			return this.theme.fg("dim", truncateToWidth(compact, width, "…"));
		}

		const left = ` ${this.document.label} · ${this.document.branch} · ${progress} · hunk ${hunk}`;
		const right = `${status ? `${status} · ` : ""}${controls} `;
		const gap = " ".repeat(Math.max(1, width - visibleWidth(left) - visibleWidth(right)));
		return `${this.theme.fg("dim", left)}${gap}${this.theme.fg("dim", right)}`;
	}

	private renderSeparator(width: number): string {
		return this.theme.fg("border", `├${"─".repeat(Math.max(0, width - 2))}┤`);
	}

	private renderFrameLine(content: string, width: number): string {
		return `${this.theme.fg("border", "│")}${fitAnsi(content, Math.max(1, width - 2))}${this.theme.fg("border", "│")}`;
	}

	private scrollBy(delta: number): void {
		this.scrollOffset = clamp(this.scrollOffset + delta, 0, this.maxScrollOffset);
		this.syncHunkToScroll();
		this.notice = undefined;
		this.requestRender();
	}

	private syncHunkToScroll(): void {
		const row = this.currentRows(this.activeLayout)[this.scrollOffset];
		if (row) this.hunkIndex = row.hunkIndex;
	}

	private moveHunk(delta: number): void {
		const file = this.selectedFile();
		if (!file || file.metadata.hunks.length === 0) return;
		this.hunkIndex = clamp(this.hunkIndex + delta, 0, file.metadata.hunks.length - 1);
		const rows = this.currentRows(this.activeLayout);
		const target = rows.findIndex((row) => row.hunkIndex === this.hunkIndex);
		if (target >= 0)
			this.scrollOffset = clamp(target, 0, Math.max(0, rows.length - this.bodyHeight()));
		this.requestRender();
	}

	private moveFile(delta: number): void {
		if (this.document.files.length === 0) return;
		this.fileIndex =
			(this.fileIndex + delta + this.document.files.length) % this.document.files.length;
		this.hunkIndex = 0;
		this.scrollOffset = 0;
		this.notice = undefined;
		this.resetRows();
		this.ensureHighlighted();
		this.requestRender();
	}

	private ensureHighlighted(): void {
		const file = this.selectedFile();
		if (!file || file.highlighted || file.highlightPending) return;
		file.highlightPending = true;
		const selected = file;
		void highlightFile(file)
			.then((highlighted) => {
				if (this.disposed) return;
				selected.highlighted = highlighted;
				this.resetRows();
			})
			.catch((error) => {
				if (this.disposed) return;
				this.notice = `Highlight failed: ${error instanceof Error ? error.message : String(error)}`;
			})
			.finally(() => {
				selected.highlightPending = false;
				if (!this.disposed) this.requestRender();
			});
	}

	private reload(): void {
		if (this.refreshing) return;
		this.refreshing = true;
		this.notice = undefined;
		this.requestRender();
		const selectedName = this.selectedFile()?.metadata.name;

		void this.callbacks
			.refresh()
			.then((document) => {
				if (this.disposed) return;
				this.document = document;
				const nextIndex = selectedName
					? document.files.findIndex((file) => file.metadata.name === selectedName)
					: -1;
				this.fileIndex = Math.max(0, nextIndex);
				this.hunkIndex = 0;
				this.scrollOffset = 0;
				this.resetRows();
				this.ensureHighlighted();
			})
			.catch((error) => {
				if (!this.disposed) {
					this.notice = `Refresh failed: ${error instanceof Error ? error.message : String(error)}`;
				}
			})
			.finally(() => {
				this.refreshing = false;
				if (!this.disposed) this.requestRender();
			});
	}

	private requestRender(): void {
		this.tui.requestRender();
	}
}

function statusLetter(file: PreparedDiffFile): string {
	switch (file.metadata.type) {
		case "new":
			return "A";
		case "deleted":
			return "D";
		case "rename-pure":
		case "rename-changed":
			return "R";
		default:
			return "M";
	}
}

function statusColor(file: PreparedDiffFile): "success" | "error" | "warning" | "muted" {
	switch (file.metadata.type) {
		case "new":
			return "success";
		case "deleted":
			return "error";
		case "rename-pure":
		case "rename-changed":
			return "warning";
		default:
			return "muted";
	}
}

function fileDisplayName(file: PreparedDiffFile): string {
	const current = safeText(file.metadata.name);
	const previous = file.metadata.prevName ? safeText(file.metadata.prevName) : undefined;
	return previous && previous !== current ? `${previous} → ${current}` : current;
}

function diffRail(kind: DiffCell["kind"]): string {
	if (kind === "addition") return "▌";
	if (kind === "deletion") return "┊";
	return " ";
}

function cellPalette(kind: DiffCell["kind"]) {
	switch (kind) {
		case "addition":
			return {
				emphasisBg: COLORS.additionEmphasisBg,
				gutterBg: COLORS.additionGutterBg,
				gutterFg: COLORS.addition,
				rowBg: COLORS.additionBg,
			};
		case "deletion":
			return {
				emphasisBg: COLORS.deletionEmphasisBg,
				gutterBg: COLORS.deletionGutterBg,
				gutterFg: COLORS.deletion,
				rowBg: COLORS.deletionBg,
			};
		case "empty":
			return {
				emphasisBg: COLORS.emptyBg,
				gutterBg: COLORS.emptyBg,
				gutterFg: COLORS.number,
				rowBg: COLORS.emptyBg,
			};
		default:
			return {
				emphasisBg: undefined,
				gutterBg: COLORS.contextGutterBg,
				gutterFg: COLORS.number,
				rowBg: COLORS.contextBg,
			};
	}
}

function renderSpans(spans: HighlightSpan[], rowBg?: string, emphasisBg?: string): string {
	return spans
		.map((span) => colorText(span.text, span.fg, span.emphasis ? emphasisBg : rowBg))
		.join("");
}

function fitAnsi(value: string, width: number): string {
	if (width <= 0) return "";
	const clipped = truncateToWidth(value, width, "");
	return `${clipped}${RESET}${" ".repeat(Math.max(0, width - visibleWidth(clipped)))}`;
}

function fitAnsiWithBackground(value: string, width: number, background?: string): string {
	if (width <= 0) return "";
	const clipped = truncateToWidth(value, width, "");
	const padding = Math.max(0, width - visibleWidth(clipped));
	return `${clipped}${RESET}${background ? paintPadding(padding, background) : " ".repeat(padding)}`;
}

function paintPadding(width: number, background: string): string {
	return width > 0 ? colorText(" ".repeat(width), undefined, background) : "";
}

function colorText(text: string, foreground?: string, background?: string): string {
	if (!text) return "";
	const prefix = `${ansiColor("fg", foreground)}${ansiColor("bg", background)}`;
	return prefix ? `${prefix}${text}${RESET}` : text;
}

function ansiColor(kind: "fg" | "bg", color: string | undefined): string {
	const normalized = color?.replace(/^#/, "");
	if (!normalized || !/^[0-9a-f]{6}$/i.test(normalized)) return "";
	const red = Number.parseInt(normalized.slice(0, 2), 16);
	const green = Number.parseInt(normalized.slice(2, 4), 16);
	const blue = Number.parseInt(normalized.slice(4, 6), 16);
	return `\x1b[${kind === "fg" ? 38 : 48};2;${red};${green};${blue}m`;
}

function safeText(value: string): string {
	return value
		.replace(/\x1b(?:\[[0-?]*[ -/]*[@-~]|\][^\x07]*(?:\x07|\x1b\\))/g, "")
		.replace(/[\u0000-\u001f\u007f]/g, "�");
}

function clamp(value: number, minimum: number, maximum: number): number {
	return Math.min(Math.max(value, minimum), maximum);
}
