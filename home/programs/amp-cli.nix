{
  config,
  pkgs,
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
    hash = "sha256-cqkEfFSSa5BlwJyzp3ngNgHSS4w8pLZw8NpY9+Lk2RM=";
  };
in
{
  programs.amp-cli = {
    enable = true;
    package = pkgs.amp-cli;
    pluginMode = "all";

    skills = {
      clickhouse-best-practices = clickhouse-agent-skills + "/skills/clickhouse-best-practices";
      duckdb-attach-db = duckdb-skills + "/skills/attach-db";
      duckdb-docs = duckdb-skills + "/skills/duckdb-docs";
      duckdb-install = duckdb-skills + "/skills/install-duckdb";
      duckdb-query = duckdb-skills + "/skills/query";
      duckdb-read-file = duckdb-skills + "/skills/read-file";
      duckdb-read-memories = duckdb-skills + "/skills/read-memories";
    };

    mcpServers = {
      "confidence-flags" = {
        url = "https://mcp.confidence.dev/mcp/flags";
      };
      "confidence-docs" = {
        url = "https://mcp.confidence.dev/mcp/docs";
      };
      "confidence-experiments" = {
        type = "http";
        url = "https://mcp.confidence.dev/mcp/experiments";
      };
      grafana = {
        command = "uvx";
        args = [ "mcp-grafana" ];
        env = {
          GRAFANA_URL = "https://lovable.grafana.net";
        };
      };
    };

    # Keep personal workflow instructions outside this repository.
    agentConfigSource = "${config.home.homeDirectory}/.config/amp/AGENTS.private.md";

    settings = {
      "amp.dangerouslyAllowAll" = true;
      "amp.agent.deepReasoningEffort" = "high";
      "amp.git.commit.coauthor.enabled" = false;
      "amp.git.commit.ampThread.enabled" = false;
      "amp.notifications.enabled" = true;
      "amp.notifications.system.enabled" = true;
    };
  };
}
