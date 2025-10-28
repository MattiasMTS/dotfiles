{ pkgs }:
let
  # Build hyperscript (missing from nixpkgs)
  hyperscript = pkgs.python313Packages.buildPythonPackage rec {
    pname = "hyperscript";
    version = "0.3.0";
    format = "pyproject";

    src = pkgs.fetchPypi {
      inherit pname version;
      hash = "sha256-d+k3LAnb8OwOGFFc1+E6RMrHy/gANioerCbZ+MSr4qg=";
    };

    nativeBuildInputs = with pkgs.python313Packages; [ setuptools-scm ];

    doCheck = false;
  };

  # Build sqlglot with the version required by sqlmesh
  sqlglot_27_28 = pkgs.python313Packages.sqlglot.overrideAttrs (old: rec {
    version = "27.28.0";
    src = pkgs.fetchPypi {
      pname = "sqlglot";
      inherit version;
      hash = "sha256-nu3JJIExo8IU3AsPdQBuEie26OhPeng8XX9U9kJZDqo=";
    };
  });
in
# Build sqlmesh with LSP support
pkgs.python313Packages.buildPythonPackage rec {
  pname = "sqlmesh";
  version = "0.226.0";
  format = "pyproject";

  src = pkgs.fetchPypi {
    inherit pname version;
    hash = "sha256-qKO7TUig9uJxvT4s/hrt9lp2wz1jhs4kJ72/7blv3Io=";
  };

  nativeBuildInputs = with pkgs.python313Packages; [
    setuptools
    wheel
    setuptools-scm
  ];

  propagatedBuildInputs = [
    hyperscript
    sqlglot_27_28
  ]
  ++ (with pkgs.python313Packages; [
    astor
    click
    croniter
    duckdb
    dateparser
    humanize
    ipywidgets
    jinja2
    pandas
    pydantic
    python-dotenv
    requests
    rich
    ruamel-yaml
    tenacity
    time-machine
    packaging
    # LSP specific dependencies
    watchfiles
    pygls
    lsprotocol
    pyarrow
    fastapi
    sse-starlette
    # Engine specific (bigquery)
    google-cloud-bigquery
    google-cloud-bigquery-storage
  ]);

  doCheck = false;
  dontCheckRuntimeDeps = true;

  meta = with pkgs.lib; {
    description = "SQLMesh with LSP support for IDE integration";
    homepage = "https://sqlmesh.com";
    license = licenses.asl20;
    maintainers = [ ];
  };
}
