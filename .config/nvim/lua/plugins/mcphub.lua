return {
  -- TODO: fix npm for nix
  {
    "ravitemer/mcphub.nvim",
    enabled = false,
    build = "npm install -g mcp-hub@latest",
    event = "VeryLazy",
    opts = {},
  },
}
