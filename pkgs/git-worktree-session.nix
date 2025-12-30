{ pkgs }:
pkgs.stdenv.mkDerivation {
  pname = "git-worktree-session";
  version = "1.0.0";
  src = ../scripts;
  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    for script in git-worktree-session git-worktree-picker sesh-list; do
      cp $script $out/bin/
      chmod +x $out/bin/$script
      wrapProgram $out/bin/$script \
        --prefix PATH : ${
          pkgs.lib.makeBinPath [
            pkgs.git
            pkgs.tmux
            pkgs.fzf
            pkgs.gawk
            pkgs.sesh
          ]
        }
    done
  '';
}
