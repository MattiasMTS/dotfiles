return {
  {
    "ravitemer/mcphub.nvim",
    enabled = false,
    -- build = "", # Managed by flake.nix
    cmd = "MCPHub",
    event = "VeryLazy",
    opts = {
      config = vim.fn.expand("$HOME/src/github.com/projects/dotfiles/.config/mcphub/servers.json"),
      port = 37373,
    },
    keys = {
      { "<leader>mc", "<cmd>MCPHub<CR>", desc = "Toggle MCPHub" },
    },
  },
}
