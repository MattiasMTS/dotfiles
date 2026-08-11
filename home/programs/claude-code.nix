{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.claude-code = {
    enable = true;
    package = inputs.claude-code-nix.packages.${pkgs.system}.claude-code;
    context = builtins.readFile (config.xdg.configHome + "/claude-code/memory.md");

    skills = import ./skills.nix { inherit pkgs; };

    mcpServers = {
      "confidence-flags" = {
        type = "http";
        url = "https://mcp.confidence.dev/mcp/flags";
      };
      "confidence-docs" = {
        type = "http";
        url = "https://mcp.confidence.dev/mcp/docs";
      };
      "confidence-experiments" = {
        type = "http";
        url = "https://mcp.confidence.dev/mcp/experiments";
      };
      "slack" = {
        type = "http";
        url = "https://mcp.slack.com/mcp";
        oauth = {
          clientId = "1601185624273.8899143856786";
          callbackPort = 3118;
        };
      };
    };

    # schema: https://json.schemastore.org/claude-code-settings.json
    settings = {
      permissions = {
        allow = [
          "Bash(go:build:*)"
          "Bash(go:test:*)"
          "Bash(go:doc:*)"
          "Bash(gh:pr:*)"
          "Bash(gh:search:*)"
          "Bash(gh:run:*)"
        ];
        deny = [
          "Read(./.env)"
          "Read(./.env.*)"
          "Read(./secrets/**)"
          "Bash(gh:pr:merge)"
          "Bash(gh:run:delete)"
        ];
        defaultMode = "auto";
      };
      skipAutoPermissionPrompt = true;
      sandbox = {
        allowUnsandboxedCommands = true;
      };
      model = "claude-opus-4-7[1m]";
      statusLine = {
        type = "command";
        command = "wt list statusline --claude-code";
      };
      alwaysThinkingEnabled = true;
      reasoningEffort = "highest";
      teammateMode = "auto";
      extraKnownMarketplaces = {
        "astral-sh" = {
          source = {
            source = "github";
            repo = "astral-sh/claude-code-plugins";
          };
        };
        "duckdb" = {
          source = {
            source = "github";
            repo = "duckdb/duckdb-skills";
          };
        };
        "temporalio-agent-skills" = {
          source = {
            source = "github";
            repo = "temporalio/agent-skills";
          };
        };
        "openai-codex" = {
          source = {
            source = "github";
            repo = "openai/codex-plugin-cc";
          };
        };
      };
      enabledPlugins = {
        "code-simplifier@claude-plugins-official" = true;
        "ralph-loop@claude-plugins-official" = true;
        "worktrunk@worktrunk" = true;
        "astral@astral-sh" = true;
        "duckdb-skills@duckdb" = true;
        "temporal-developer@temporalio-agent-skills" = true;
        "codex@openai-codex" = true;
      };
      notifications = {
        "sound" = true;
        "onQuestion" = true;
        "onIdle" = true;
      };
    };
  };
}
