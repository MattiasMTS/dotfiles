return {
  {
    "mrjones2014/smart-splits.nvim",
    event = "BufEnter",
    opts = {
      default_amount = 7,
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
    },
  },
}
