{ pkgs, ... }: {
  enable = true;

  package = pkgs.go_1_24;
  goPath = "go";
  goBin = ".local/bin.go";
  goPrivate = [ "github.com/epidemicsound" ];
  packages = { };
}

