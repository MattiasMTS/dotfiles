{
  pkgs,
  lib,
  inputs,
  peon-ping,
  username,
  ...
}:
{
  enable = true;
  package = inputs.claude-code-nix.packages.${pkgs.system}.claude-code;
  memory = {
    text = builtins.readFile /Users/${username}/.config/claude-code/memory.txt;
  };

  mcpServers = {
    "confidence-flags" = {
      type = "http";
      url = "https://mcp.confidence.dev/mcp/flags";
    };
    "confidence-docs" = {
      type = "http";
      url = "https://mcp.confidence.dev/mcp/docs";
    };
    "grafana" = {
      type = "stdio";
      command = "uvx";
      args = [ "mcp-grafana" ];
      env = {
        GRAFANA_URL = "https://lovable.grafana.net";
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
        "LSP"
      ];
      deny = [
        "Read(./.env)"
        "Read(./.env.*)"
        "Read(./secrets/**)"
        "Bash(gh:pr:merge)"
        "Bash(gh:run:delete)"
      ];
      defaultMode = "bypassPermissions";
    };
    sandbox = {
      allowUnsandboxedCommands = true;
    };
    model = "opus";
    statusLine = {
      type = "command";
      command = "wt list statusline --claude-code";
    };
    alwaysThinkingEnabled = true;
    teammateMode = "auto";
    extraKnownMarketplaces = {
      "astral-sh" = {
        source = {
          source = "github";
          repo = "astral-sh/claude-code-plugins";
        };
      };
    };
    enabledPlugins = {
      "code-simplifier@claude-plugins-official" = true;
      "ralph-wiggum@claude-plugins-official" = true;
      "worktrunk@worktrunk" = true;
      "lua-lsp@claude-plugins-official" = true;
      "gopls-lsp@claude-plugins-official" = true;
      "astral@astral-sh" = true;
      "typescript-lsp@claude-plugins-official" = true;
    };
    notifications = {
      "sound" = true;
      "onQuestion" = true;
      "onIdle" = true;
    };
    hooks = {
      UserPromptSubmit = [
        {
          hooks = [
            {
              type = "command";
              command = "${peon-ping}/bin/peon";
              timeout = 10;
            }
          ];
        }
      ];
      Stop = [
        {
          hooks = [
            {
              type = "command";
              command = "${peon-ping}/bin/peon";
              timeout = 10;
            }
          ];
        }
      ];
      Notification = [
        {
          hooks = [
            {
              type = "command";
              command = "${peon-ping}/bin/peon";
              timeout = 10;
            }
          ];
        }
      ];
      PermissionRequest = [
        {
          hooks = [
            {
              type = "command";
              command = "${peon-ping}/bin/peon";
              timeout = 10;
            }
          ];
        }
      ];
      PostToolUseFailure = [
        {
          hooks = [
            {
              type = "command";
              command = "${peon-ping}/bin/peon";
              timeout = 10;
            }
          ];
        }
      ];
      SubagentStart = [
        {
          hooks = [
            {
              type = "command";
              command = "${peon-ping}/bin/peon";
              timeout = 10;
            }
          ];
        }
      ];
      PreCompact = [
        {
          hooks = [
            {
              type = "command";
              command = "${peon-ping}/bin/peon";
              timeout = 10;
            }
          ];
        }
      ];
    };
  };

}
