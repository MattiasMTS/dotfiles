return {
  {
    "saghen/blink.cmp",
    dependencies = {
      {
        "saghen/blink.compat",
        version = "*",
        lazy = true,
      },
      { "rafamadriz/friendly-snippets" },
    },
    -- build = "cargo build --release", # TODO: build it via nix instead
    event = { "InsertEnter", "CmdlineEnter" },
    opts = {
      fuzzy = {
        implementation = "lua",
      },
      keymap = {
        preset = "default",
        -- better selection
        ["<CR>"] = { "select_and_accept", "fallback" },
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },

        -- enable snippet jumping
        ["<Tab>"] = {
          "snippet_forward",
          function()
            return vim.lsp.inline_completion.get()
          end,
          "fallback",
        },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },

        -- better navigation
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        ["<C-e>"] = { "hide" },
      },
      completion = {
        menu = {
          scrollbar = false,
          draw = {
            treesitter = { "lsp" },
            gap = 2,
            columns = {
              { "kind_icon", "kind", gap = 1 },
              { "label", "label_description", gap = 1 },
            },
          },
        },
        list = {
          selection = { preselect = true, auto_insert = false },
          max_items = 200,
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
        },
        ghost_text = { enabled = false },
      },
      signature = {
        enabled = true,
        trigger = {
          show_on_keyword = true,
          enabled = true,
          show_on_insert = true,
          show_on_trigger_character = true,
        },
        window = {
          max_width = 50,
          min_width = 50,
          max_height = 20,
          border = "double",
          treesitter_highlighting = true,
          show_documentation = true,
        },
      },
      cmdline = {
        enabled = true,
        keymap = {
          preset = "cmdline",
          ["<Right>"] = false,
          ["<Left>"] = false,
          ["<C-j>"] = { "select_next", "fallback" },
          ["<C-k>"] = { "select_prev", "fallback" },
          ["<Down>"] = { "select_next", "fallback" },
          ["<Up>"] = { "select_prev", "fallback" },
        },
        completion = {
          list = { selection = { preselect = false } },
          menu = {
            auto_show = function(_)
              return vim.fn.getcmdtype() == ":"
            end,
          },
          ghost_text = { enabled = true },
        },
      },

      sources = {
        default = { "lsp", "path", "snippets", "lazydev" },
        providers = {
          lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
        },
      },
    },
    config = function(_, opts)
      require("blink.cmp").setup(opts)
    end,
  },
  -- add cmp-dbee separate to not clutter the main config
  -- {
  --   "saghen/blink.cmp",
  --   dependencies = {
  --     "MattiasMTS/cmp-dbee",
  --     enabled = true,
  --     ft = { "sql" },
  --     dev = true,
  --     dependencies = { "kndndrj/nvim-dbee" },
  --   },
  --   opts = {
  --     sources = {
  --       compat = { "dbee" },
  --       providers = {
  --         dbee = { name = "dbee", module = "blink.compat.source" },
  --       },
  --     },
  --   },
  -- },
}
