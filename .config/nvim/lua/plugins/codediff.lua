return {
  {
    "esmuellert/codediff.nvim",
    cmd = "CodeDiff",
    opts = {
      explorer = {
        view_mode = "tree", -- tree | list
        initial_focus = "modified",
      },
      history = {
        initial_focus = "modified",
      },
      keymaps = {
        view = {
          next_hunk = "]c",
          prev_hunk = "[c",
          next_file = "<Tab>",
          prev_file = "<S-Tab>",
        },
        explorer = {
          select = "<CR>",
          hover = "K",
          refresh = "R",
        },
      },
    },
    keys = {
      { "<leader>do", ":CodeDiff main...<CR>", desc = "Toggle CodeDiff against main", silent = true },
      { "<leader>dh", ":CodeDiff history %<CR>", desc = "File history", silent = true },
      { "<leader>dH", ":CodeDiff history<CR>", desc = "Repo history", silent = true },
    },
  },
}
