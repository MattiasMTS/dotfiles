{ pkgs, ... }: {
  enable = true;

  package = pkgs.go_1_24;
  goPath = "go";
  goBin = "go/bin";
}

