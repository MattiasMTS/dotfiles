{ pkgs, ... }:
{
  enable = true;

  package = pkgs.go_1_25;
  goPath = "go";
  goBin = "go/bin";
}
