return {
  {
    "nvim-lualine/lualine.nvim",
    enabled = true,
    event = "BufEnter",
    config = function()
      -- build a transparent theme from catppuccin
      local theme = require("lualine.themes.catppuccin-nvim")
      for _, mode in pairs(theme) do
        for _, section in pairs(mode) do
          section.bg = "NONE"
        end
      end

      require("lualine").setup({
        options = {
          component_separators = "",
          section_separators = "",
          theme = theme,
          globalstatus = true,
          disabled_filetypes = { statusline = { "dashboard", "lazy" } },
        },
        sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = {},
          lualine_x = {
            "diagnostics",
            "lsp_status",
          },
          lualine_y = {},
          lualine_z = {},
        },
        extensions = { "quickfix", "neo-tree", "fzf", "lazy" },
      })

      -- force transparent statusline background
      vim.api.nvim_set_hl(0, "StatusLine", { bg = "NONE" })
      vim.api.nvim_set_hl(0, "StatusLineNC", { bg = "NONE" })
    end,
  },
  {
    "akinsho/bufferline.nvim",
    enabled = true,
    event = "VeryLazy",
    keys = {
      {
        "<leader>bd",
        function()
          _G.Snacks.bufdelete()
        end,
        desc = "Delete Buffer",
      },
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
        always_show_bufferline = true,
        show_buffer_close_icons = false,
        show_close_icon = true,
        show_tab_indicators = false,
        separator_style = { "", "" },
        indicator = { style = "none" },
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
