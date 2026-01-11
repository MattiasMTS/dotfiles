return {
  {
    "mrjones2014/smart-splits.nvim",
    lazy = false,
    opts = {
      default_amount = 7,
      ignored_buftypes = { "nofile" },
      cursor_follows_swapped_bufs = true,
    },
    keys = {
      -- cursor movement
      { "<C-l>", ":SmartCursorMoveRight<CR>", silent = true },
      { "<C-h>", ":SmartCursorMoveLeft<CR>", silent = true },
      { "<C-j>", ":SmartCursorMoveDown<CR>", silent = true },
      { "<C-k>", ":SmartCursorMoveUp<CR>", silent = true },
      -- resizing
      { "<M-h>", ":SmartResizeLeft<CR>", silent = true },
      { "<M-j>", ":SmartResizeDown<CR>", silent = true },
      { "<M-k>", ":SmartResizeUp<CR>", silent = true },
      { "<M-l>", ":SmartResizeRight<CR>", silent = true },
      -- swap buffer
      { "<leader><leader>l", ":SmartSwapRight<CR>", silent = true },
      { "<leader><leader>h", ":SmartSwapLeft<CR>", silent = true },
      { "<leader><leader>j", ":SmartSwapDown<CR>", silent = true },
      { "<leader><leader>k", ":SmartSwapUp<CR>", silent = true },
    },
  },
}
