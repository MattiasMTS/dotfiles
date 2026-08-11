{ pkgs }:
let
  version = "1.0.0";
  artifacts = {
    aarch64-darwin = {
      os = "darwin";
      arch = "arm64";
      hash = "sha256-XCesCNDW2CpjRo119Bv+g1NuF++om2MpB2/LLaBGpnI=";
    };
    x86_64-darwin = {
      os = "darwin";
      arch = "amd64";
      hash = "sha256-OD/u4ureXZQUErSdPFCLrSy8UIigFsf3e/rQ65r+GYQ=";
    };
    aarch64-linux = {
      os = "linux";
      arch = "arm64";
      hash = "sha256-YF9rt0BtFEvRHHL/JWSasXIpaZvlhaJTRgt3OW3FdYU=";
    };
    x86_64-linux = {
      os = "linux";
      arch = "amd64";
      hash = "sha256-yIxllY0Z2D3DoZKipQN+CDB6nHdgGfJCSbifNpycTUE=";
    };
  };
  artifact =
    artifacts.${pkgs.stdenv.hostPlatform.system}
      or (throw "gcx: unsupported platform ${pkgs.stdenv.hostPlatform.system}");
  source = pkgs.fetchFromGitHub {
    owner = "grafana";
    repo = "gcx";
    rev = "v${version}";
    hash = "sha256-VBYYlPzuZ9iQMXUJdxu9YBPs2Ize6vWBzhMK94E3beY=";
  };
in
{
  package = pkgs.stdenvNoCC.mkDerivation {
    pname = "gcx";
    inherit version;

    src = pkgs.fetchurl {
      url = "https://github.com/grafana/gcx/releases/download/v${version}/gcx_${version}_${artifact.os}_${artifact.arch}.tar.gz";
      inherit (artifact) hash;
    };
    sourceRoot = ".";

    nativeBuildInputs = [ pkgs.installShellFiles ];

    installPhase = ''
      runHook preInstall

      install -Dm755 gcx "$out/bin/gcx"
      installShellCompletion --cmd gcx \
        --bash <("$out/bin/gcx" completion bash) \
        --fish <("$out/bin/gcx" completion fish) \
        --zsh <("$out/bin/gcx" completion zsh)

      runHook postInstall
    '';

    meta = {
      description = "Grafana CLI";
      homepage = "https://github.com/grafana/gcx";
      license = pkgs.lib.licenses.asl20;
      mainProgram = "gcx";
      platforms = builtins.attrNames artifacts;
    };
  };

  skills = "${source}/claude-plugin/skills";
}
