final: prev: {
  amp-cli = final.buildNpmPackage {
    pname = "amp-cli";
    version = "0.0.1773432280-gcd86a7";

    src = final.fetchzip {
      url = "https://registry.npmjs.org/@sourcegraph/amp/-/amp-0.0.1773432280-gcd86a7.tgz";
      hash = "sha256-7VB2T48wBFIZ7lwzY9kv/9SuaGUtZIyILGiyMOROaDY=";
    };

    postPatch = ''
      cp ${./amp-cli-lock.json} package-lock.json

      cat > package.json <<EOF
      {
        "name": "amp-cli",
        "version": "0.0.0",
        "license": "UNLICENSED",
        "dependencies": {
          "@sourcegraph/amp": "0.0.1773432280-gcd86a7"
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

    npmDepsHash = "sha256-klQCBZu9gZuYAtvq/0ywDp3n57YWkoZH48VUURntsfI=";

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
