import {
	formatOwnedTitle,
	parseOwnedTitle,
	type LifecycleState,
	type SessionStartReason,
} from "./state.ts";

export interface TitleIO {
	read(): Promise<string | undefined>;
	rename(title: string): Promise<boolean>;
	clear(): Promise<boolean>;
}

export class TitleOwner {
	private disabled = false;
	private ownedTitle: string | undefined;
	private readonly io: TitleIO;

	constructor(io: TitleIO) {
		this.io = io;
	}

	get titleWritesDisabled(): boolean {
		return this.disabled;
	}

	get expectedTitle(): string | undefined {
		return this.ownedTitle;
	}

	async recoverOrReset(
		reason: SessionStartReason,
		automaticBaseTitle?: string,
	): Promise<LifecycleState | undefined> {
		if (this.disabled) return undefined;
		const title = await this.readCertain();
		if (title === undefined) return undefined;
		const owned = parseOwnedTitle(title);
		if (
			reason === "reload" &&
			owned &&
			(owned.state === "completed" || owned.state === "error" || owned.state === "cancelled")
		) {
			this.ownedTitle = title;
			await this.mark(owned.state, false, automaticBaseTitle);
			return owned.state;
		}
		this.ownedTitle = owned ? title : undefined;
		await this.mark("idle", true, automaticBaseTitle);
		return "idle";
	}

	async mark(
		state: LifecycleState,
		allowAcquire: boolean,
		automaticBaseTitle?: string,
	): Promise<void> {
		if (this.disabled) return;
		const title = await this.readCertain();
		if (title === undefined) return;
		if (this.ownedTitle && title !== this.ownedTitle) {
			this.ownedTitle = undefined;
			// Explicit session-name and run-start projections may race with Pi's
			// automatic OSC title. Re-probe only when acquisition is allowed: an
			// automatic title is safely replaced, while a manual override is restored.
			if (!allowAcquire) return;
		}

		const owned = parseOwnedTitle(title);
		if (!owned && !allowAcquire) return;
		const preservesManualTitle = owned?.preservesManualTitle ?? (await this.probeManual(title));
		if (preservesManualTitle === undefined || this.disabled) return;
		const baseTitle = preservesManualTitle
			? (owned?.baseTitle ?? title)
			: (automaticBaseTitle ?? owned?.baseTitle ?? title);
		const requested = formatOwnedTitle(state, baseTitle, preservesManualTitle);
		await this.renameOwned(requested);
	}

	async release(): Promise<void> {
		if (this.disabled || !this.ownedTitle) return;
		const expected = this.ownedTitle;
		const title = await this.readCertain();
		if (title === undefined) return;
		if (title !== expected) {
			this.ownedTitle = undefined;
			return;
		}
		const owned = parseOwnedTitle(title);
		if (!owned) {
			this.ownedTitle = undefined;
			return;
		}

		const commandOk = owned.preservesManualTitle
			? await this.io.rename(owned.baseTitle)
			: await this.io.clear();
		const observed = await this.io.read();
		if (observed === owned.baseTitle) {
			this.ownedTitle = undefined;
			return;
		}
		if (observed !== undefined && observed !== expected) {
			this.ownedTitle = undefined;
			this.disable();
			return;
		}
		if (!commandOk || observed === undefined || observed === expected) this.disable();
	}

	private async probeManual(title: string): Promise<boolean | undefined> {
		const clearOk = await this.io.clear();
		const afterClear = await this.io.read();
		if (afterClear === undefined) {
			// clear-name may have committed before the read failed. Restore the
			// original resolved title conservatively, then stop mutating this session.
			await this.io.rename(title);
			await this.io.read();
			this.disable();
			return undefined;
		}
		if (afterClear === title) {
			if (!clearOk) this.disable();
			return clearOk ? false : undefined;
		}

		// clear-name exposed a manual title. Restore it even when clear reported
		// failure, then verify the rollback before taking ownership.
		await this.io.rename(title);
		const restored = await this.io.read();
		if (restored !== title) {
			this.disable();
			return undefined;
		}
		return true;
	}

	private async renameOwned(requested: string): Promise<void> {
		const previous = this.ownedTitle;
		const commandOk = await this.io.rename(requested);
		const observed = await this.io.read();
		if (observed === requested) {
			this.ownedTitle = requested;
			return;
		}
		if (previous && observed === previous) {
			this.ownedTitle = previous;
			this.disable();
			return;
		}
		this.ownedTitle = undefined;
		if (!commandOk || observed === undefined) this.disable();
	}

	private async readCertain(): Promise<string | undefined> {
		const title = await this.io.read();
		if (title === undefined) this.disable();
		return title;
	}

	private disable(): void {
		this.disabled = true;
	}
}
