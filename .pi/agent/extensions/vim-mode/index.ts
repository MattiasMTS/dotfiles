/**
 * Local vim-mode extension for Pi.
 *
 * Adapted from burneikis/pi-vim (MIT):
 * https://github.com/burneikis/pi-vim
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { ImagePlaceholderRegistry } from "./image-placeholders.js";
import { VimEditor } from "./vim-editor.js";

export default function (pi: ExtensionAPI) {
	const imagePlaceholders = new ImagePlaceholderRegistry();

	pi.on("session_start", (_event, ctx) => {
		ctx.ui.setEditorComponent(
			(tui, theme, keybindings) => new VimEditor(tui, theme, keybindings, imagePlaceholders),
		);
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
