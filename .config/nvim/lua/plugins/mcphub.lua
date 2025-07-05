return {
  {
    "ravitemer/mcphub.nvim",
    enabled = true,
    -- build = "", # Managed by flake.nix
    event = "VeryLazy",
    opts = {
      config = vim.fn.expand("$HOME/src/github.com/projects/dotfiles/.config/mcphub/servers.json"),
      port = 37373,
    },
    keys = {
      {
        "<leader>mc",
        "<cmd>MCPHub<CR>",
        desc = "Toggle MCPHub",
      },
    },
  },
}
