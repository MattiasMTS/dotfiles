{
  pkgs,
  username,
  ...
}:
let
  GOPATH = "/Users/${username}/go";
in
{
  programs.go = {
    enable = true;

    package = pkgs.go_1_26;
    env = {
      inherit GOPATH;
      GOBIN = "${GOPATH}/bin";
    };
  };
}
