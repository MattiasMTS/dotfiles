import * as path from "node:path";

export function repositoryNameFromRemote(remoteUrl: string): string | undefined {
	const normalized = remoteUrl
		.trim()
		.replace(/[?#].*$/, "")
		.replace(/[\\/]+$/, "");
	if (!normalized) return undefined;
	const leaf = normalized.split(/[\\/:]/).at(-1);
	if (!leaf) return undefined;
	return leaf.endsWith(".git") && leaf.length > 4 ? leaf.slice(0, -4) : leaf;
}

/**
 * Give a generic cmux workspace the Git checkout directory's basename. cmux's
 * custom-title provenance protects explicit/topic names; a title equal to the
 * origin repository name is still generic and may be corrected.
 */
export function gitWorkspaceRenameTarget(
	workspaceTitle: string,
	hasCustomTitle: boolean,
	gitTopLevel: string,
	repositoryName?: string,
): string | undefined {
	const current = workspaceTitle.trim();
	const checkoutName = path.basename(gitTopLevel.trim());
	if (!checkoutName || current === checkoutName) return undefined;
	if (!hasCustomTitle || (repositoryName !== undefined && current === repositoryName)) {
		return checkoutName;
	}
	return undefined;
}
