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
in
{
  programs.amp-cli = {
    enable = true;
    package = pkgs.amp-cli;
    pluginMode = "all";

    skills = {
      clickhouse-best-practices = clickhouse-agent-skills + "/skills/clickhouse-best-practices";
    };

    mcpServers = {
      "confidence-flags" = {
        url = "https://mcp.confidence.dev/mcp/flags";
      };
      "confidence-docs" = {
        url = "https://mcp.confidence.dev/mcp/docs";
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
      "amp.terminal.theme" = "catppuccin-mocha";
    };
  };
}
