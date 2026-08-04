/**
 * Local vim-mode extension for Pi.
 *
 * Adapted from burneikis/pi-vim (MIT):
 * https://github.com/burneikis/pi-vim
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import type { TextContent, ImageContent } from "@earendil-works/pi-ai";
import { ImagePlaceholderRegistry } from "./image-placeholders.js";
import { VimEditor } from "./vim-editor.js";

function userMessageText(content: string | (TextContent | ImageContent)[]): string {
	if (typeof content === "string") return content;
	return content
		.filter((part): part is TextContent => part.type === "text")
		.map((part) => part.text)
		.join("\n");
}

export default function (pi: ExtensionAPI) {
	const imagePlaceholders = new ImagePlaceholderRegistry();

	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setEditorComponent((tui, theme, keybindings) => {
			const editor = new VimEditor(tui, theme, keybindings, imagePlaceholders);

			// Seed native up/down history recall from past session messages so
			// it works right after /new or session resume, not only for
			// messages typed during this run.
			for (const entry of ctx.sessionManager.getBranch()) {
				if (entry.type !== "message" || entry.message.role !== "user") continue;
				const text = userMessageText(entry.message.content).trim();
				if (text) editor.addToHistory(text);
			}

			return editor;
		});
	});

	pi.on("input", (event, ctx) => {
		const replaced = imagePlaceholders.replaceImagePaths(event.text, ctx.cwd);
		const images = imagePlaceholders.consumeImagesForText(replaced.text);
		if (!replaced.changed && images.length === 0) {
			return { action: "continue" };
		}

		return {
			action: "transform",
			text: replaced.text,
			images: [...(event.images ?? []), ...images],
		};
	});
}
