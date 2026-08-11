{
  config,
  pkgs,
  inputs,
  ...
}:
let
  clickhouse-agent-skills = pkgs.fetchFromGitHub {
    owner = "ClickHouse";
    repo = "agent-skills";
    rev = "main";
    hash = "sha256-5QwMvgOlqVZwCNwNNNt2CwtM6dk+Fww1EjagA9fezVQ=";
  };
  duckdb-skills = pkgs.fetchFromGitHub {
    owner = "duckdb";
    repo = "duckdb-skills";
    rev = "main";
    hash = "sha256-13dPimt/Gf7coSQe6q1vF7yQwSUoTJSucP9URAxf9VA=";
  };
  temporal-developer-skill = pkgs.fetchFromGitHub {
    owner = "temporalio";
    repo = "skill-temporal-developer";
    rev = "main";
    hash = "sha256-fB3sn8X3GL1sCWy3HrejLHf+tIbFAC9M5WYBM5gPTsA=";
  };
in
{
  programs.codex = {
    enable = true;
    package = inputs.codex-nix.packages.${pkgs.system}.codex;

    skills = {
      clickhouse-best-practices = "${clickhouse-agent-skills}/skills/clickhouse-best-practices";
      duckdb-attach-db = "${duckdb-skills}/skills/attach-db";
      duckdb-docs = "${duckdb-skills}/skills/duckdb-docs";
      duckdb-install = "${duckdb-skills}/skills/install-duckdb";
      duckdb-query = "${duckdb-skills}/skills/query";
      duckdb-read-file = "${duckdb-skills}/skills/read-file";
      duckdb-read-memories = "${duckdb-skills}/skills/read-memories";
      temporal-developer = "${temporal-developer-skill}";
    };

    # https://developers.openai.com/codex/config-reference
    settings = {
      model = "gpt-5.5";
      model_provider = "openai";
      model_reasoning_effort = "xhigh";
      model_reasoning_summary = "detailed";

      sandbox_mode = "workspace-write";
      approval_policy = "on-request";

      mcp_servers = {
        confidence-flags = {
          url = "https://mcp.confidence.dev/mcp/flags";
        };
        confidence-docs = {
          url = "https://mcp.confidence.dev/mcp/docs";
        };
        confidence-experiments = {
          url = "https://mcp.confidence.dev/mcp/experiments";
        };
      };
    };
  };
}
