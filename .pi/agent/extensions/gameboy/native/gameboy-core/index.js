const fs = require("node:fs");
const path = require("node:path");

let native = null;
let loadError = null;

function candidatePaths() {
	const dir = __dirname;
	const triples = [
		`${process.platform}-${process.arch}`,
		`${process.platform}-${process.arch}-gnu`,
		`${process.platform}-${process.arch}-msvc`,
		`${process.platform}-${process.arch}-musl`,
	];

	const names = [];
	for (const triple of triples) {
		names.push(`pi-gameboy-core.${triple}.node`);
		names.push(`pi_gameboy_core.${triple}.node`);
	}
	names.push("pi-gameboy-core.node", "pi_gameboy_core.node");

	const explicit = names.map((name) => path.join(dir, name));
	let globbed = [];
	try {
		globbed = fs
			.readdirSync(dir)
			.filter((name) => name.endsWith(".node"))
			.map((name) => path.join(dir, name));
	} catch {
		globbed = [];
	}
	return [...explicit, ...globbed];
}

for (const candidate of candidatePaths()) {
	try {
		native = require(candidate);
		loadError = null;
		break;
	} catch (error) {
		if (error && error.code !== "MODULE_NOT_FOUND") {
			loadError = error && error.stack ? error.stack : String(error);
		} else if (!loadError) {
			loadError = String(error);
		}
	}
}

if (!native && !loadError) {
	loadError = "Native addon not built. Run scripts/build-pi-gameboy.";
}

module.exports = {
	isAvailable: Boolean(native && native.NativeGameboy),
	loadError,
	NativeGameboy: native ? native.NativeGameboy : undefined,
};
