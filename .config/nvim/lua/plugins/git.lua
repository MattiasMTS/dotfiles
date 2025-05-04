return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      current_line_blame = true, -- Toggle with `:Gitsigns toggle_current_line_blame`
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol", -- 'eol' | 'overlay' | 'right_align'
        delay = 500, -- unit in ms
        ignore_whitespace = false,
        virt_text_priority = 200,
      },
      current_line_blame_formatter = "  <author>, <author_time:%Y-%m-%d> - <summary>",
      max_file_length = 40000, -- Disable if file is longer than this (in lines)
      on_attach = function()
        local gs = require("gitsigns")
        vim.keymap.set("n", "<leader>gb", function()
          gs.blame_line({ full = true })
        end, { desc = "Blame Line full" })
      end,
    },
  },
  {
    "9seconds/repolink.nvim",
    enabled = true,
    dependencies = { "nvim-lua/plenary.nvim" },
    cmd = "RepoLink",
    opts = {},
    keys = {
      { "<leader>gy", "<cmd>RepoLink!<cr>", mode = { "n", "v" }, desc = "Yank git link" },
    },
  },
}
