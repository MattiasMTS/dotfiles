import { existsSync, readFileSync, statSync } from "node:fs";
import path from "node:path";

export interface PendingImageContent {
	type: "image";
	data: string;
	mimeType: string;
}

interface PendingImage {
	marker: string;
	content: PendingImageContent;
	path: string;
}

const IMAGE_MIME_BY_EXT: Record<string, string> = {
	".png": "image/png",
	".jpg": "image/jpeg",
	".jpeg": "image/jpeg",
	".webp": "image/webp",
	".gif": "image/gif",
};

const IMAGE_PATH_PATTERN =
	/(?:"([^"]+\.(?:png|jpe?g|webp|gif))"|'([^']+\.(?:png|jpe?g|webp|gif))'|((?:\/|~\/|\.\/|\.\.\/)\S+?\.(?:png|jpe?g|webp|gif)))/gi;
const MARKER_PATTERN = /\[Image #(\d+)\]/g;
const MAX_IMAGE_BYTES = 25 * 1024 * 1024;

function resolveImagePath(rawPath: string): string | undefined {
	if (!path.isAbsolute(rawPath)) return undefined;
	return rawPath;
}

function mimeTypeForPath(filePath: string): string | undefined {
	return IMAGE_MIME_BY_EXT[path.extname(filePath).toLowerCase()];
}

export class ImagePlaceholderRegistry {
	private nextImageNumber = 1;
	private pending = new Map<string, PendingImage>();

	reset(): void {
		this.nextImageNumber = 1;
		this.pending.clear();
	}

	addImagePath(rawPath: string): string | undefined {
		const resolvedPath = resolveImagePath(rawPath);
		if (!resolvedPath) return undefined;
		const mimeType = mimeTypeForPath(resolvedPath);
		if (!mimeType || !existsSync(resolvedPath)) return undefined;

		const stat = statSync(resolvedPath);
		if (!stat.isFile() || stat.size <= 0 || stat.size > MAX_IMAGE_BYTES) {
			return undefined;
		}

		const marker = `[Image #${this.nextImageNumber++}]`;
		this.pending.set(marker, {
			marker,
			path: resolvedPath,
			content: {
				type: "image",
				data: readFileSync(resolvedPath).toString("base64"),
				mimeType,
			},
		});
		return marker;
	}

	replaceImagePaths(text: string, _cwd?: string): { text: string; changed: boolean } {
		let changed = false;
		IMAGE_PATH_PATTERN.lastIndex = 0;
		const next = text.replace(IMAGE_PATH_PATTERN, (match, doubleQuoted, singleQuoted, bare) => {
			const rawPath = doubleQuoted ?? singleQuoted ?? bare;
			if (!rawPath) return match;

			const marker = this.addImagePath(rawPath);
			if (!marker) return match;

			changed = true;
			return marker;
		});

		return { text: next, changed };
	}

	consumeImagesForText(text: string): PendingImageContent[] {
		const images: PendingImageContent[] = [];
		const seen = new Set<string>();

		MARKER_PATTERN.lastIndex = 0;
		for (const match of text.matchAll(MARKER_PATTERN)) {
			const marker = match[0];
			if (seen.has(marker)) continue;
			seen.add(marker);

			const pending = this.pending.get(marker);
			if (pending) images.push(pending.content);
		}

		this.reset();
		return images;
	}
}
