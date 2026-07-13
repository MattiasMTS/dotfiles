# overlays/default.nix
# Aggregates all overlays - just add new files to this directory
{ }:
[
  (import ./graphite-cli.nix)
]
