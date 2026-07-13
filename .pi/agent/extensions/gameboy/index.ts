import * as fs from "node:fs/promises";
import * as path from "node:path";
import * as os from "node:os";
import type { ExtensionAPI, ExtensionCommandContext } from "@earendil-works/pi-coding-agent";
import {
	allocateImageId,
	deleteKittyImage,
	getCapabilities,
	getCellDimensions,
	isKeyRelease,
	matchesKey,
	visibleWidth,
	type Component,
	type TUI,
} from "@earendil-works/pi-tui";

const nativeCore = require("./native/gameboy-core") as NativeCore;

const SCREEN_WIDTH = 160;
const SCREEN_HEIGHT = 144;
const FRAME_BYTES = SCREEN_WIDTH * SCREEN_HEIGHT * 4;
const CONFIG_PATH = path.join(os.homedir(), ".pi", "gameboy", "config.json");
const FOOTER =
	"GB | Ctrl+Q=Detach | Q=Quit | HJKL/Arrows=Move | S=A | A=B | Enter/Space=Start | Tab=Select";
const BUTTONS = ["up", "down", "left", "right", "a", "b", "start", "select"] as const;
const DEFAULT_MAX_WIDTH = 96;
const RAW_FRAME_BYTES = SCREEN_WIDTH * SCREEN_HEIGHT * 3;
const PALETTES = {
	dmg: [
		[15, 56, 15],
		[48, 98, 48],
		[139, 172, 15],
		[155, 188, 15],
	],
	grayscale: [
		[0, 0, 0],
		[85, 85, 85],
		[170, 170, 170],
		[255, 255, 255],
	],
} as const;

const DEFAULT_CONFIG: GameboyConfig = {
	romDir: "~/roms/gb",
	frameRate: 60,
	maxWidth: DEFAULT_MAX_WIDTH,
	palette: "dmg",
	renderer: "auto",
	keybindings: {
		up: ["up", "k", "K"],
		down: ["down", "j", "J"],
		left: ["left", "h", "H"],
		right: ["right", "l", "L"],
		a: ["s", "S"],
		b: ["a", "A"],
		start: ["enter", "space"],
		select: ["tab"],
	},
};

type Button = (typeof BUTTONS)[number];

type Keybindings = Record<Button, string[]>;
type PaletteName = keyof typeof PALETTES;
type RendererMode = "auto" | "kitty" | "text";

interface GameboyConfig {
	romDir: string;
	frameRate: number;
	maxWidth: number;
	palette: PaletteName;
	renderer: RendererMode;
	keybindings: Keybindings;
}

interface NativeGameboy {
	stepFrame(): void;
	getFrameBuffer(): Buffer;
	setButton(button: string, pressed: boolean): void;
	dispose(): void;
}

interface NativeCore {
	isAvailable: boolean;
	loadError: string | null;
	NativeGameboy?: new (rom: Buffer, romPath?: string) => NativeGameboy;
}

let activeSession: GameboySession | undefined;

export default function (pi: ExtensionAPI) {
	pi.on("session_shutdown", () => {
		activeSession?.dispose();
		activeSession = undefined;
	});

	pi.registerCommand("gb", {
		description: "Play a Game Boy ROM in the Pi TUI",
		handler: async (args, ctx) => {
			if (!ensureTui(ctx, "/gb")) return;
			if (!ensureNative(ctx)) return;

			try {
				const config = await loadConfig();
				const explicitRom = args.trim().length > 0;
				const romPath = await chooseRom(args.trim(), config, ctx);
				if (!romPath) return;

				if (
					explicitRom &&
					activeSession &&
					!activeSession.disposed &&
					activeSession.romPath !== romPath
				) {
					activeSession.dispose();
					activeSession = undefined;
				}

				if (!activeSession || activeSession.disposed) {
					activeSession = await createSession(romPath, config);
				}

				await attachSession(activeSession, config, ctx);
			} catch (error) {
				ctx.ui.notify(errorMessage(error), "error");
			}
		},
	});

	pi.registerCommand("gb-config", {
		description: "Edit Game Boy emulator config",
		handler: async (_args, ctx) => {
			if (!ensureTui(ctx, "/gb-config")) return;

			try {
				const config = await loadConfig();
				const edited = await ctx.ui.editor(
					"Edit Game Boy config",
					JSON.stringify(config, null, "\t") + "\n",
				);
				if (edited === undefined) return;

				let parsed: unknown;
				try {
					parsed = JSON.parse(edited);
				} catch (error) {
					throw new Error(`Invalid JSON: ${errorMessage(error)}`);
				}

				const normalized = normalizeConfig(parsed);
				await saveConfig(normalized);
				if (activeSession && !activeSession.disposed) {
					activeSession.setFrameRate(normalized.frameRate);
				}
				ctx.ui.notify(`Saved ${CONFIG_PATH}`, "info");
			} catch (error) {
				ctx.ui.notify(errorMessage(error), "error");
			}
		},
	});
}

async function chooseRom(
	args: string,
	config: GameboyConfig,
	ctx: ExtensionCommandContext,
): Promise<string | undefined> {
	if (args) {
		return resolvePath(args, ctx.cwd || process.cwd());
	}

	if (activeSession && !activeSession.disposed) {
		return activeSession.romPath;
	}

	const romDir = resolvePath(config.romDir, ctx.cwd || process.cwd());
	let entries: string[];
	try {
		await fs.mkdir(romDir, { recursive: true });
		entries = await listRoms(romDir);
	} catch (error) {
		throw new Error(`Failed to list ROMs in ${romDir}: ${errorMessage(error)}`);
	}

	if (entries.length === 0) {
		ctx.ui.notify(`No .gb or .gbc ROMs found in ${romDir}`, "warning");
		return undefined;
	}

	const choice = await ctx.ui.select("Select Game Boy ROM", entries);
	return choice ? path.join(romDir, choice) : undefined;
}

async function createSession(romPath: string, config: GameboyConfig): Promise<GameboySession> {
	const NativeGameboy = nativeCore.NativeGameboy;
	if (!NativeGameboy) throw new Error("Native addon not available");

	const rom = await fs.readFile(romPath);
	return new GameboySession(new NativeGameboy(rom, romPath), romPath, config.frameRate);
}

async function attachSession(
	session: GameboySession,
	config: GameboyConfig,
	ctx: ExtensionCommandContext,
): Promise<void> {
	if (session.attached) {
		ctx.ui.notify("Game Boy session already attached", "warning");
		return;
	}

	session.setFrameRate(config.frameRate);
	await ctx.ui.custom((tui, _theme, _keybindings, done) => {
		const component = new GameboyComponent(session, config, tui, (action) => {
			component.dispose();
			if (action === "quit") {
				session.dispose();
				if (activeSession === session) activeSession = undefined;
			} else {
				session.detach();
			}
			done(undefined);
		});
		session.attach(component);
		return component;
	});
}

class GameboySession {
	private interval: ReturnType<typeof setInterval> | undefined;
	private component: GameboyComponent | undefined;
	private pressed = new Set<Button>();
	private frameMs: number;
	public disposed = false;
	public attached = false;

	constructor(
		private readonly emulator: NativeGameboy,
		public readonly romPath: string,
		frameRate: number,
	) {
		this.frameMs = frameRateToMs(frameRate);
		this.startTimer();
	}

	setFrameRate(frameRate: number): void {
		const next = frameRateToMs(frameRate);
		if (next === this.frameMs) return;
		this.frameMs = next;
		this.startTimer();
	}

	attach(component: GameboyComponent): void {
		this.component = component;
		this.attached = true;
	}

	detach(): void {
		this.releaseAll();
		this.component = undefined;
		this.attached = false;
	}

	setButton(button: Button, pressed: boolean): void {
		if (this.disposed) return;
		if (pressed && this.pressed.has(button)) return;
		if (!pressed && !this.pressed.has(button)) return;

		this.emulator.setButton(button, pressed);
		if (pressed) {
			this.pressed.add(button);
		} else {
			this.pressed.delete(button);
		}
	}

	frameBuffer(): Buffer {
		return this.emulator.getFrameBuffer();
	}

	dispose(): void {
		if (this.disposed) return;
		this.releaseAll();
		if (this.interval) clearInterval(this.interval);
		this.interval = undefined;
		this.component = undefined;
		this.attached = false;
		this.disposed = true;
		this.emulator.dispose();
	}

	private startTimer(): void {
		if (this.interval) clearInterval(this.interval);
		if (this.disposed) return;
		this.interval = setInterval(() => {
			try {
				this.emulator.stepFrame();
				this.component?.markFrame();
			} catch {
				this.dispose();
			}
		}, this.frameMs);
	}

	private releaseAll(): void {
		for (const button of [...this.pressed]) {
			try {
				this.emulator.setButton(button, false);
			} catch {
				// Ignore release errors during shutdown.
			}
		}
		this.pressed.clear();
	}
}

class GameboyImageRenderer {
	private readonly imageId = allocateImageId();
	private readonly rawBuffer = Buffer.alloc(RAW_FRAME_BYTES);
	private rawVersion = 0;
	private lastLines: string[] = [];

	render(
		frame: Buffer,
		tui: TUI,
		width: number,
		maxWidth: number,
		palette: PaletteName,
		forceKitty: boolean,
	): string[] | undefined {
		if (!forceKitty && getCapabilities().images !== "kitty") return undefined;
		try {
			const layout = kittyLayout(tui, width, maxWidth);
			fillRawRgb(frame, this.rawBuffer, palette);

			const sequence = encodeKittyRawDirect(this.rawBuffer.toString("base64"), {
				columns: layout.columns,
				rows: layout.rows,
				imageId: this.imageId,
			});
			const lines = Array.from({ length: Math.max(0, layout.rows - 1) }, () => "");
			const moveUp = layout.rows > 1 ? `\x1b[${layout.rows - 1}A` : "";
			this.rawVersion++;
			lines.push(
				`${moveUp}${" ".repeat(layout.padLeft)}${sequence}\x1b_pi:gb:${this.rawVersion}\x07`,
			);
			this.lastLines = lines;
			return lines;
		} catch {
			return this.lastLines.length > 0 ? [...this.lastLines] : undefined;
		}
	}

	dispose(tui: TUI): void {
		tui.terminal.write(deleteKittyImage(this.imageId));
		this.lastLines = [];
	}
}

class GameboyComponent implements Component {
	wantsKeyRelease = true;
	private cachedWidth = 0;
	private cachedVersion = -1;
	private cachedLines: string[] = [];
	private version = 0;

	private readonly imageRenderer = new GameboyImageRenderer();

	constructor(
		private readonly session: GameboySession,
		private readonly config: GameboyConfig,
		private readonly tui: TUI,
		private readonly close: (action: "detach" | "quit") => void,
	) {}

	markFrame(): void {
		this.version++;
		this.tui.requestRender();
	}

	handleInput(data: string): void {
		const released = isKeyRelease(data);

		if (!released && matchesKey(data, "ctrl+q")) {
			this.close("detach");
			return;
		}

		if (!released && (data === "q" || data === "Q" || matchesKey(data, "q"))) {
			this.close("quit");
			return;
		}

		for (const button of BUTTONS) {
			if (this.matchesBindings(data, this.config.keybindings[button])) {
				this.session.setButton(button, !released);
			}
		}
	}

	invalidate(): void {
		this.cachedWidth = 0;
	}

	render(width: number): string[] {
		if (width === this.cachedWidth && this.cachedVersion === this.version) {
			return this.cachedLines;
		}

		const usableWidth = Math.max(1, width);
		const frame = this.safeFrame();
		const imageLines =
			this.config.renderer === "text"
				? undefined
				: this.imageRenderer.render(
						frame,
						this.tui,
						usableWidth,
						this.config.maxWidth,
						this.config.palette,
						this.config.renderer === "kitty",
					);
		const lines =
			imageLines ??
			renderHalfBlock(frame, usableWidth, this.config.maxWidth, this.config.palette);

		lines.push(
			truncateAnsiFree(
				`${horizontalPad(usableWidth, Math.min(usableWidth, this.config.maxWidth))}${FOOTER}`,
				usableWidth,
			),
		);

		this.cachedWidth = width;
		this.cachedVersion = this.version;
		this.cachedLines = lines;
		return lines;
	}

	private matchesBindings(data: string, bindings: string[]): boolean {
		return bindings.some((binding) => matchesConfiguredKey(data, binding));
	}

	private safeFrame(): Buffer {
		try {
			const frame = this.session.frameBuffer();
			if (frame.length >= FRAME_BYTES) return frame;
		} catch {
			// Fall through to blank frame.
		}
		return Buffer.alloc(FRAME_BYTES, 0xff);
	}

	dispose(): void {
		this.imageRenderer.dispose(this.tui);
	}
}

async function loadConfig(): Promise<GameboyConfig> {
	try {
		const raw = await fs.readFile(CONFIG_PATH, "utf8");
		return normalizeConfig(JSON.parse(raw));
	} catch (error) {
		const code = (error as NodeJS.ErrnoException).code;
		if (code !== "ENOENT")
			throw new Error(`Failed to read ${CONFIG_PATH}: ${errorMessage(error)}`);
		await saveConfig(DEFAULT_CONFIG);
		return cloneConfig(DEFAULT_CONFIG);
	}
}

async function saveConfig(config: GameboyConfig): Promise<void> {
	await fs.mkdir(path.dirname(CONFIG_PATH), { recursive: true });
	await fs.writeFile(CONFIG_PATH, JSON.stringify(config, null, "\t") + "\n", "utf8");
}

function normalizeConfig(value: unknown): GameboyConfig {
	if (!isRecord(value)) throw new Error("Config must be a JSON object");

	const romDir = value.romDir ?? DEFAULT_CONFIG.romDir;
	if (typeof romDir !== "string" || romDir.trim() === "") {
		throw new Error("Config romDir must be a non-empty string");
	}

	const frameRateRaw = value.frameRate ?? DEFAULT_CONFIG.frameRate;
	if (typeof frameRateRaw !== "number" || !Number.isFinite(frameRateRaw)) {
		throw new Error("Config frameRate must be a number");
	}
	const frameRate = Math.round(frameRateRaw);
	if (frameRate < 1 || frameRate > 240) {
		throw new Error("Config frameRate must be between 1 and 240");
	}

	const maxWidthRaw = value.maxWidth ?? DEFAULT_CONFIG.maxWidth;
	if (typeof maxWidthRaw !== "number" || !Number.isFinite(maxWidthRaw)) {
		throw new Error("Config maxWidth must be a number");
	}
	const maxWidth = Math.round(maxWidthRaw);
	if (maxWidth < 20 || maxWidth > SCREEN_WIDTH) {
		throw new Error(`Config maxWidth must be between 20 and ${SCREEN_WIDTH}`);
	}

	const paletteRaw = value.palette ?? DEFAULT_CONFIG.palette;
	if (paletteRaw !== "dmg" && paletteRaw !== "grayscale") {
		throw new Error('Config palette must be "dmg" or "grayscale"');
	}
	const palette = paletteRaw;

	const rendererRaw = value.renderer ?? DEFAULT_CONFIG.renderer;
	if (rendererRaw !== "auto" && rendererRaw !== "kitty" && rendererRaw !== "text") {
		throw new Error('Config renderer must be "auto", "kitty", or "text"');
	}
	const renderer = rendererRaw;

	const sourceBindings = isRecord(value.keybindings) ? value.keybindings : {};
	const keybindings = {} as Keybindings;
	for (const button of BUTTONS) {
		const raw = sourceBindings[button] ?? DEFAULT_CONFIG.keybindings[button];
		if (
			!Array.isArray(raw) ||
			raw.some((item) => typeof item !== "string" || item.trim() === "")
		) {
			throw new Error(`Config keybindings.${button} must be a non-empty string array`);
		}
		keybindings[button] = [...new Set(raw.map((item) => item.trim()))];
	}

	return { romDir: romDir.trim(), frameRate, maxWidth, palette, renderer, keybindings };
}

async function listRoms(dir: string): Promise<string[]> {
	const entries = await fs.readdir(dir, { withFileTypes: true });
	return entries
		.filter((entry) => entry.isFile() && /\.(gb|gbc)$/i.test(entry.name))
		.map((entry) => entry.name)
		.sort((a, b) => a.localeCompare(b));
}

function ensureTui(ctx: ExtensionCommandContext, command: string): boolean {
	if (ctx.mode === "tui") return true;
	ctx.ui.notify(`${command} requires Pi TUI mode`, "error");
	return false;
}

function ensureNative(ctx: ExtensionCommandContext): boolean {
	if (nativeCore.isAvailable) return true;
	ctx.ui.notify(
		`Game Boy native addon not built. Run scripts/build-pi-gameboy. ${nativeCore.loadError ?? ""}`.trim(),
		"error",
	);
	return false;
}

function resolvePath(input: string, cwd: string): string {
	const expanded =
		input === "~"
			? os.homedir()
			: input.startsWith("~/")
				? path.join(os.homedir(), input.slice(2))
				: input;
	return path.isAbsolute(expanded) ? expanded : path.resolve(cwd, expanded);
}

function matchesConfiguredKey(data: string, binding: string): boolean {
	if (data === binding) return true;
	const key = binding as Parameters<typeof matchesKey>[1];
	if (matchesKey(data, key)) return true;
	if (binding === "enter") return matchesKey(data, "return") || data === "\r" || data === "\n";
	if (binding === "space") return matchesKey(data, "space") || data === " ";
	return false;
}

function frameRateToMs(frameRate: number): number {
	return Math.max(1, Math.round(1000 / frameRate));
}

function kittyLayout(
	tui: TUI,
	width: number,
	maxWidth: number,
): {
	columns: number;
	rows: number;
	padLeft: number;
} {
	const cell = getCellDimensions();
	const availableRows = Math.max(1, tui.terminal.rows - 2);
	const maxRows = Math.max(1, Math.floor(availableRows * 0.9));
	const maxColumns = Math.max(1, Math.min(width, maxWidth));
	const scale = Math.min(
		(maxColumns * cell.widthPx) / SCREEN_WIDTH,
		(maxRows * cell.heightPx) / SCREEN_HEIGHT,
	);
	const columns = Math.max(
		1,
		Math.min(maxColumns, Math.floor((SCREEN_WIDTH * scale) / cell.widthPx)),
	);
	const rows = Math.max(
		1,
		Math.min(maxRows, Math.floor((SCREEN_HEIGHT * scale) / cell.heightPx)),
	);
	return { columns, rows, padLeft: Math.max(0, Math.floor((width - columns) / 2)) };
}

function encodeKittyRawDirect(
	base64Data: string,
	options: { columns: number; rows: number; imageId: number },
): string {
	const chunkSize = 4096;
	const params = [
		"a=T",
		"f=24",
		"t=d",
		"p=1",
		"q=2",
		`s=${SCREEN_WIDTH}`,
		`v=${SCREEN_HEIGHT}`,
		`S=${RAW_FRAME_BYTES}`,
		`c=${options.columns}`,
		`r=${options.rows}`,
		`i=${options.imageId}`,
		"z=0",
	];
	if (base64Data.length <= chunkSize) {
		return `\x1b_G${params.join(",")};${base64Data}\x1b\\`;
	}

	const chunks: string[] = [];
	let offset = 0;
	let first = true;
	while (offset < base64Data.length) {
		const chunk = base64Data.slice(offset, offset + chunkSize);
		const last = offset + chunkSize >= base64Data.length;
		if (first) {
			chunks.push(`\x1b_G${params.join(",")},m=1;${chunk}\x1b\\`);
			first = false;
		} else if (last) {
			chunks.push(`\x1b_Gm=0;${chunk}\x1b\\`);
		} else {
			chunks.push(`\x1b_Gm=1;${chunk}\x1b\\`);
		}
		offset += chunkSize;
	}
	return chunks.join("");
}

function fillRawRgb(frame: Buffer, target: Buffer, palette: PaletteName): void {
	let rawOffset = 0;
	for (let y = 0; y < SCREEN_HEIGHT; y++) {
		for (let x = 0; x < SCREEN_WIDTH; x++) {
			const color = displayPixel(frame, x, y, palette);
			target[rawOffset++] = color.r;
			target[rawOffset++] = color.g;
			target[rawOffset++] = color.b;
		}
	}
}

function pixel(frame: Buffer, x: number, y: number): { r: number; g: number; b: number } {
	const offset = (y * SCREEN_WIDTH + x) * 4;
	return { r: frame[offset] ?? 0, g: frame[offset + 1] ?? 0, b: frame[offset + 2] ?? 0 };
}

function displayPixel(
	frame: Buffer,
	x: number,
	y: number,
	palette: PaletteName,
): { r: number; g: number; b: number } {
	const raw = pixel(frame, x, y);
	if (palette === "grayscale") return raw;
	const luminance = (raw.r * 299 + raw.g * 587 + raw.b * 114) / 1000;
	const shade = clamp(Math.round(luminance / 85), 0, 3);
	const [r, g, b] = PALETTES[palette][shade];
	return { r, g, b };
}

function renderHalfBlock(
	frame: Buffer,
	width: number,
	maxWidth: number,
	palette: PaletteName,
): string[] {
	const imageWidth = Math.max(1, Math.min(SCREEN_WIDTH, width, maxWidth));
	const padPrefix = horizontalPad(width, imageWidth);
	const scale = SCREEN_WIDTH / imageWidth;
	const imageRows = Math.max(1, Math.ceil(SCREEN_HEIGHT / (2 * scale)));
	const lines: string[] = [];

	for (let row = 0; row < imageRows; row++) {
		let line = padPrefix;
		const topY = clamp(Math.floor(row * 2 * scale), 0, SCREEN_HEIGHT - 1);
		const bottomY = clamp(Math.floor((row * 2 + 1) * scale), 0, SCREEN_HEIGHT - 1);
		for (let col = 0; col < imageWidth; col++) {
			const x = clamp(Math.floor(col * scale), 0, SCREEN_WIDTH - 1);
			const top = displayPixel(frame, x, topY, palette);
			const bottom = displayPixel(frame, x, bottomY, palette);
			line += `\x1b[38;2;${top.r};${top.g};${top.b}m\x1b[48;2;${bottom.r};${bottom.g};${bottom.b}m▀`;
		}
		lines.push(line + "\x1b[0m");
	}

	return lines;
}

function horizontalPad(width: number, imageWidth: number): string {
	return " ".repeat(Math.max(0, Math.floor((width - imageWidth) / 2)));
}

function clamp(value: number, min: number, max: number): number {
	return Math.max(min, Math.min(max, value));
}

function truncateAnsiFree(value: string, width: number): string {
	if (visibleWidth(value) <= width) return value;
	return value.slice(0, Math.max(0, width));
}

function cloneConfig(config: GameboyConfig): GameboyConfig {
	return {
		romDir: config.romDir,
		frameRate: config.frameRate,
		maxWidth: config.maxWidth,
		palette: config.palette,
		renderer: config.renderer,
		keybindings: Object.fromEntries(
			BUTTONS.map((button) => [button, [...config.keybindings[button]]]),
		) as Keybindings,
	};
}

function isRecord(value: unknown): value is Record<string, unknown> {
	return typeof value === "object" && value !== null && !Array.isArray(value);
}

function errorMessage(error: unknown): string {
	return error instanceof Error ? error.message : String(error);
}
