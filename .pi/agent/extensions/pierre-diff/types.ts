import type { FileDiffMetadata } from "@pierre/diffs";

export type DiffLayout = "split" | "stack";
export type DiffSourceKind = "working" | "staged" | "revision";
export type DiffLineKind = "context" | "addition" | "deletion" | "empty";

export interface DiffSourceRequest {
	kind: DiffSourceKind;
	revision?: string;
	paths: string[];
}

export interface HighlightSpan {
	text: string;
	fg?: string;
	emphasis?: boolean;
}

export interface HighlightedDiff {
	additionLines: Array<HastNode | undefined>;
	deletionLines: Array<HastNode | undefined>;
}

export interface PreparedDiffFile {
	metadata: FileDiffMetadata;
	additions: number;
	deletions: number;
	highlighted?: HighlightedDiff;
	highlightPending?: boolean;
}

export interface DiffDocument {
	branch: string;
	files: PreparedDiffFile[];
	label: string;
	notices: string[];
	totalAdditions: number;
	totalDeletions: number;
}

export type HastNode = HastTextNode | HastElementNode;

interface HastTextNode {
	type: "text";
	value: string;
}

interface HastElementNode {
	type: "element";
	tagName: string;
	properties?: Record<string, unknown>;
	children?: HastNode[];
}

export interface DiffCell {
	kind: DiffLineKind;
	oldLine?: number;
	newLine?: number;
	spans: HighlightSpan[];
}

export type DiffRow =
	| {
			type: "collapsed";
			hunkIndex: number;
			text: string;
	  }
	| {
			type: "hunk-header";
			hunkIndex: number;
			text: string;
	  }
	| {
			type: "stack-line";
			hunkIndex: number;
			cell: DiffCell;
	  }
	| {
			type: "split-line";
			hunkIndex: number;
			left: DiffCell;
			right: DiffCell;
	  };
