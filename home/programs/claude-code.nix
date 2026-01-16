{
  pkgs,
  lib,
  inputs,
  ...
}:
{
  enable = true;
  package = inputs.claude-code-nix.packages.${pkgs.system}.claude-code;
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
    };
    model = "opus";
    statusLine = {
      type = "command";
      command = "wt list statusline --claude-code";
    };
    alwaysThinkingEnabled = true;
    enabledPlugins = {
      "code-simplifier@claude-plugins-official" = true;
      "ralph-wiggum@claude-plugins-official" = true;
      "worktrunk@worktrunk" = true;
    };
    notifications = {
      "sound" = true;
      "onQuestion" = true;
      "onIdle" = true;
    };
    mcpServers = {
      "confidence-flags" = {
        command = "http";
        url = "https://mcp.confidence.dev/mcp/flags";
      };
      "confidence-docs" = {
        command = "http";
        url = "https://mcp.confidence.dev/mcp/docs";
      };
    };
  };
}
