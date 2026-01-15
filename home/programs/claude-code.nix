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
      ];
      deny = [
        "Read(./.env)"
        "Read(./.env.*)"
        "Read(./secrets/**)"
      ];
      model = "opus";
      statusLine = {
        type = "command";
        command = "wt list statusline --claude-code";
      };
      alwaysThinkingEnabled = true;
    };
    enabledPlugins = {
      "code-simplifier@claude-plugins-official" = true;
      "ralph-wiggum@claude-plugins-official" = true;
      "worktrunk@worktrunk" = true;
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
