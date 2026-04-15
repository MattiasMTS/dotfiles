final: prev:
let
  version = "0.0.1776142372-g88c61d";
  tarballHash = "sha256-VQ/F1mLT+iaQRwQu8KCFywm6k4kKPTldn+O/sY8lM2c=";
  nodeModulesHash = "sha256-lTW9dhKiVLFuvOWKBCf4JaVdBI2725ef9Xs02q0T6Vk=";

  src = final.fetchurl {
    url = "https://registry.npmjs.org/@sourcegraph/amp/-/amp-${version}.tgz";
    hash = tarballHash;
  };

  nodeModules = final.stdenvNoCC.mkDerivation {
    pname = "amp-cli-node-modules";
    inherit version src;

    dontConfigure = true;
    dontFixup = true;
    dontUnpack = true;

    nativeBuildInputs = [
      final.bun
      final.writableTmpDirAsHomeHook
    ];

    buildPhase = ''
      runHook preBuild

      mkdir source
      tar -xzf $src -C source --strip-components=1
      cd source

      export BUN_INSTALL_CACHE_DIR=$(mktemp -d)
      bun install \
        --cpu="*" \
        --ignore-scripts \
        --no-progress \
        --os="*" \
        --production

      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall

      rm -rf node_modules/.bin
      mkdir -p $out
      cp -R . $out

      runHook postInstall
    '';

    outputHash = nodeModulesHash;
    outputHashAlgo = "sha256";
    outputHashMode = "recursive";
  };
in
{
  amp-cli = final.stdenvNoCC.mkDerivation {
    pname = "amp-cli";
    inherit version;
    src = nodeModules;

    dontUnpack = true;
    nativeBuildInputs = [ final.makeWrapper ];

    installPhase = ''
      runHook preInstall

      mkdir -p $out/bin $out/lib/node_modules/@sourcegraph
      cp -R $src $out/lib/node_modules/@sourcegraph/amp

      makeWrapper ${final.bun}/bin/bun $out/bin/amp \
        --add-flags "$out/lib/node_modules/@sourcegraph/amp/dist/main.js" \
        --prefix PATH : ${final.lib.makeBinPath [ final.ripgrep ]} \
        --set AMP_SKIP_UPDATE_CHECK 1

      runHook postInstall
    '';

    passthru = {
      inherit nodeModules;
    };

    meta = {
      description = "CLI for Amp, an agentic coding agent from Sourcegraph";
      homepage = "https://ampcode.com/";
      license = final.lib.licenses.unfree;
      mainProgram = "amp";
    };
  };
}
