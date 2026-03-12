# overlays/default.nix
# Aggregates all overlays - just add new files to this directory
{ inputs }:
[
  (import ./amp-cli.nix)
]
