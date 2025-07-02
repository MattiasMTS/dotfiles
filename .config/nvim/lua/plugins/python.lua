return {
  {
    "linux-cultist/venv-selector.nvim",
    branch = "regexp",
    event = "VeryLazy",
    dependencies = { "nvim-telescope/telescope.nvim", event = "VeryLazy" },
    opts = {
      settings = { notify_user_on_venv_activation = true },
    },
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>" },
    },
  },
}
