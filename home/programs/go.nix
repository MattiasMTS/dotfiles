{ pkgs, username, ... }:
let
  GOPATH = "/Users/${username}/go";
in
{
  enable = true;

  package = pkgs.go_1_25;
  env = {
    GOPATH = GOPATH;
    GOBIN = "${GOPATH}/bin";
  };
}
