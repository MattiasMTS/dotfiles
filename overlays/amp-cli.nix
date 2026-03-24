final: prev: {
  amp-cli = final.buildNpmPackage {
    pname = "amp-cli";
    version = "0.0.1774240952-g432b79";

    src = final.fetchzip {
      url = "https://registry.npmjs.org/@sourcegraph/amp/-/amp-0.0.1774240952-g432b79.tgz";
      hash = "sha256-GHwRHQHn8ZkxQorueO9MBBdbbGMg3Ouw9mGj2tvUdVw=";
    };

    postPatch = ''
      cp ${./amp-cli-lock.json} package-lock.json

      cat > package.json <<EOF
      {
        "name": "amp-cli",
        "version": "0.0.0",
        "license": "UNLICENSED",
        "dependencies": {
          "@sourcegraph/amp": "0.0.1774240952-g432b79"
        },
        "bin": {
          "amp": "./bin/amp-wrapper.js"
        }
      }
      EOF

      mkdir -p bin

      cat > bin/amp-wrapper.js << EOF
      #!/usr/bin/env node
      import('@sourcegraph/amp/dist/main.js')
      EOF
      chmod +x bin/amp-wrapper.js
    '';

    npmDepsHash = "sha256-qp9FA8zLQF3aMQLbXBm91Fy4insRjmbI055L6nF55OQ=";

    propagatedBuildInputs = [ final.ripgrep ];
    nativeBuildInputs = [ final.makeWrapper ];

    npmFlags = [ "--no-audit" "--no-fund" "--ignore-scripts" ];
    dontNpmBuild = true;

    postInstall = ''
      wrapProgram $out/bin/amp \
        --prefix PATH : ${final.lib.makeBinPath [ final.ripgrep ]} \
        --set AMP_SKIP_UPDATE_CHECK 1
    '';

    meta = {
      description = "CLI for Amp, an agentic coding agent from Sourcegraph";
      homepage = "https://ampcode.com/";
      license = final.lib.licenses.unfree;
      mainProgram = "amp";
    };
  };
}
