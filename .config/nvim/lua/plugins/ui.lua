return {
  {
    "Bekaboo/dropbar.nvim",
    event = "BufEnter",
    enabled = false,
  },
  {
    "nvim-lualine/lualine.nvim",
    enabled = true,
    dev = false,
    event = "BufEnter",
    opts = {
      options = {
        component_separators = "",
        section_separators = "",
      },
      sections = {
        lualine_y = { "lsp_status" },
        lualine_z = { "encoding" },
      },
      extensions = {
        "quickfix",
        "neo-tree",
        "fzf",
        "lazy",
      },
    },
  },
  {
    "akinsho/bufferline.nvim",
    enabled = false,
    event = "VeryLazy",
    keys = {
      { "<leader>bp", "<Cmd>BufferLineTogglePin<CR>", desc = "Toggle Pin" },
      { "<leader>bP", "<Cmd>BufferLineGroupClose ungrouped<CR>", desc = "Delete Non-Pinned Buffers" },
      { "<leader>br", "<Cmd>BufferLineCloseRight<CR>", desc = "Delete Buffers to the Right" },
      { "<leader>bl", "<Cmd>BufferLineCloseLeft<CR>", desc = "Delete Buffers to the Left" },
      { "<S-h>", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "<S-l>", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[b", "<cmd>BufferLineCyclePrev<cr>", desc = "Prev Buffer" },
      { "]b", "<cmd>BufferLineCycleNext<cr>", desc = "Next Buffer" },
      { "[B", "<cmd>BufferLineMovePrev<cr>", desc = "Move buffer prev" },
      { "]B", "<cmd>BufferLineMoveNext<cr>", desc = "Move buffer next" },
    },
    opts = {
      options = {
        --stylua: ignore start
        close_command = function(n) _G.Snacks.bufdelete(n) end,
        right_mouse_command = function(n) _G.Snacks.bufdelete(n) end,
        -- stylua: ignore end
        diagnostics = "nvim_lsp",
        always_show_bufferline = false,
        offsets = {
          {
            filetype = "neo-tree",
            text = "Neo-tree",
            highlight = "Directory",
            text_align = "left",
          },
        },
      },
    },
  },
}
