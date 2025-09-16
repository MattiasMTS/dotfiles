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
    build = "cargo build --release",
    event = "InsertEnter",
    opts = {
      menu = {
        draw = {
          components = {
            kind_icon = {
              text = function(ctx)
                local kind_icon, _, _ = require("mini.icons").get("lsp", ctx.kind)
                return kind_icon
              end,
              highlight = function(ctx)
                local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                return hl
              end,
            },
            kind = {
              highlight = function(ctx)
                local _, hl, _ = require("mini.icons").get("lsp", ctx.kind)
                return hl
              end,
            },
          },
        },
      },
      keymap = {
        preset = "default",
        -- better selection
        ["<CR>"] = { "select_and_accept", "fallback" },
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },

        -- enable snippet jumping
        ["<Tab>"] = { "snippet_forward", "fallback" },
        ["<S-Tab>"] = { "snippet_backward", "fallback" },

        -- better navigation
        ["<C-j>"] = { "select_next", "fallback" },
        ["<C-k>"] = { "select_prev", "fallback" },
        ["<C-u>"] = { "scroll_documentation_up", "fallback" },
        ["<C-d>"] = { "scroll_documentation_down", "fallback" },
        ["<C-e>"] = { "hide" },
      },
      completion = {
        menu = { scrollbar = false },
        list = {
          selection = { preselect = true, auto_insert = false },
          max_items = 200,
        },
        documentation = { auto_show = true },
        ghost_text = { enabled = false },
      },
      signature = { enabled = true },
      cmdline = { enabled = false },

      sources = {
        default = { "lsp", "path", "snippets", "lazydev", "codecompanion" },
        providers = {
          lazydev = { module = "lazydev.integrations.blink", score_offset = 100 },
          codecompanion = { module = "codecompanion.providers.completion.blink" },
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
