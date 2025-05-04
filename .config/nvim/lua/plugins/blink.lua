return {
  {
    "saghen/blink.cmp",
    dependencies = {
      {
        "saghen/blink.compat",
        version = "*",
        lazy = true,
      },
      "rafamadriz/friendly-snippets",
    },
    build = "cargo build --release",
    event = "InsertEnter",
    opts = {
      appearance = {
        kind_icons = {
          Text = "󰉿",
          Method = "󰆧",
          Function = "󰊕",
          Constructor = "",

          Field = "󰜢",
          Class = "󰠱",
          Property = "󰜢",

          Variable = "󰀫",
          Interface = "",
          Module = "",
          Unit = "󰑭",
          Value = "󰎠",
          Enum = "",
          Keyword = "󰌋",
          Snippet = "",
          Color = "󰏘",
          File = "󰈙",
          Reference = "󰈇",
          Folder = "󰉋",
          EnumMember = "",
          Constant = "󰏿",
          Struct = "󰙅",
          Event = "",
          Operator = "󰆕",
          TypeParameter = "󰬛",
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
        list = {
          selection = { preselect = true, auto_insert = false },
          max_items = 10,
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
          codecompanion = { module = "codecompanion.providers.completion.blink", enabled = true },
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
