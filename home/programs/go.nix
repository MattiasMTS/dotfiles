{ pkgs, username, ... }:
{
  enable = true;

  package = pkgs.go_1_25;
  env = {
    GOPATH = "/Users/${username}/go";
    GOBIN = "/Users/${username}/go/bin";
  };
}
