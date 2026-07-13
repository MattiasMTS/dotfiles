# Two fixes for graphite-cli 1.8.6 on darwin until nixpkgs fixes them upstream:
#
# 1. `gt completion` runs at build time in postInstall, but gt exits 1 with no
#    output when HOME is not writable (the nix sandbox sets
#    HOME=/homeless-shelter), so installShellCompletion fails on an empty
#    file. writableTmpDirAsHomeHook gives the build a writable HOME.
#
# 2. The gt binary is built with vercel/pkg, which appends a virtual
#    filesystem to the executable at fixed byte offsets; stripping corrupts it
#    ("Pkg: Error reading from file."). Upstream only disables fixup on Linux
#    (via buildFHSEnv), so the darwin fixupPhase strips the binary.
final: prev: {
  graphite-cli = prev.graphite-cli.overrideAttrs (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ final.writableTmpDirAsHomeHook ];
    dontStrip = true;
  });
}
