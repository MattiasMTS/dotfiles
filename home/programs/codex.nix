{
  config,
  pkgs,
  inputs,
  ...
}:
{
  programs.codex = {
    enable = true;
    package = inputs.codex-nix.packages.${pkgs.system}.codex;

    skills = import ./skills.nix { inherit pkgs; };

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
