return {
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    event = "VeryLazy",
    dependencies = { "nvim-telescope/telescope.nvim", event = "VeryLazy" },
    opts = {},
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>" },
    },
  },
}
