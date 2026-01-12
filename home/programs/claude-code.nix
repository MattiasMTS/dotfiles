{
  pkgs,
  lib,
  ...
}:
{
  enable = true;
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
      "gopls-lsp@claude-plugins-official" = true;
      "lua-lsp@claude-plugins-official" = true;
      "typescript-lsp@claude-plugins-official" = true;
      "pyright-lsp@claude-plugins-official" = true;
      "code-simplifier@claude-plugins-official" = true;
      "worktrunk@worktrunk" = true;
    };
  };
}
