return {
  {
    "linux-cultist/venv-selector.nvim",
    event = "VeryLazy",
    enabled = true,
    opts = {
      notify_user_on_venv_activation = true,
      picker = "fzf",
    },
    keys = {
      { "<leader>cv", "<cmd>VenvSelect<cr>" },
    },
  },
}
