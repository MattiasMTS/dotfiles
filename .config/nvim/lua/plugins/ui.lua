return {
  {
    "Bekaboo/dropbar.nvim",
    event = "BufEnter",
    enabled = false,
  },
  {
    "nvim-lualine/lualine.nvim",
    enabled = true,
    event = "BufEnter",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.component_separators = ""
      opts.options.section_separators = ""

      opts.sections = opts.sections or {}
      opts.sections.lualine_y = opts.sections.lualine_y or { "lsp_status" }
      table.insert(opts.sections.lualine_x or {}, 2, {
        function()
          local status = require("sidekick.status").cli()
          return " " .. (#status > 1 and #status or "")
        end,
        cond = function()
          return #require("sidekick.status").cli() > 0
        end,
        color = function()
          return "Special"
        end,
      })

      opts.extensions = opts.extensions
        or {
          "quickfix",
          "neo-tree",
          "fzf",
          "lazy",
        }
    end,
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
