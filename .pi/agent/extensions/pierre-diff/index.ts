import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { loadDiffDocument, parseDiffRequest } from "./engine.ts";
import { PierreDiffViewer } from "./viewer.ts";

const STATUS_ID = "pierre-diff";

export default function (pi: ExtensionAPI) {
	pi.registerCommand("pdiff", {
		description:
			"Review Git changes with Pierre Diffs (/pdiff [staged|revision] [-- paths...])",
		handler: async (args, ctx) => {
			if (ctx.mode !== "tui") {
				ctx.ui.notify("/pdiff requires interactive mode", "error");
				return;
			}

			try {
				const request = await parseDiffRequest(args, ctx.cwd);
				ctx.ui.setStatus(STATUS_ID, ctx.ui.theme.fg("accent", "pdiff: loading…"));
				const document = await loadDiffDocument(pi, ctx.cwd, request);
				ctx.ui.setStatus(STATUS_ID, undefined);

				if (document.files.length === 0) {
					ctx.ui.notify(`No ${document.label} differences`, "info");
					return;
				}

				await ctx.ui.custom<void>(
					(tui, theme, _keybindings, done) =>
						new PierreDiffViewer(tui, theme, document, {
							done: () => done(),
							refresh: () => loadDiffDocument(pi, ctx.cwd, request),
						}),
					{
						overlay: true,
						overlayOptions: {
							anchor: "center",
							margin: 1,
							maxHeight: "90%",
							minWidth: 48,
							width: "96%",
						},
					},
				);
			} catch (error) {
				ctx.ui.setStatus(STATUS_ID, undefined);
				ctx.ui.notify(
					`pdiff: ${error instanceof Error ? error.message : String(error)}`,
					"error",
				);
			}
		},
	});

	pi.on("session_shutdown", (_event, ctx) => {
		ctx.ui.setStatus(STATUS_ID, undefined);
	});
}
