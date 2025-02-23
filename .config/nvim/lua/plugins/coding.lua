return {
  -- disable automatic insertion of pairs like parenthesis etc
  -- using nvim-autopairs instead
  { "echasnovski/mini.pairs", enabled = true, opts = { command = false } },
  -- no need to extend a/i
  { "echasnovski/mini.ai", enabled = false },
  {
    "saghen/blink.compat",
    version = "*",
    lazy = true, -- handled via blink.cmp
    opts = {},
  },
  {
    "saghen/blink.cmp",
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
        -- ["C-space"] = { "select_and_accept", "fallback" },
        ["<C-space>"] = { "show", "show_documentation", "hide_documentation" },

        -- enable snippet jumping
        ["<Tab>"] = {
          _G.LazyVim.cmp.map({ "snippet_forward" }),
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
      completion = { ghost_text = { enabled = false } },
    },
  },
  {
    "saghen/blink.cmp",
    dependencies = {
      "MattiasMTS/cmp-dbee",
      ft = { "sql" },
      dev = true,
      dependencies = { "kndndrj/nvim-dbee" },
    },
    opts = {
      sources = {
        compat = { "dbee" },
        providers = {
          dbee = { name = "dbee", module = "blink.compat.source" },
        },
      },
    },
  },
  {
    "ThePrimeagen/refactoring.nvim",
    enabled = false,
    keys = {
      {
        "<leader>rr",
        function()
          require("refactoring").select_refactor()
        end,
        mode = "v",
        noremap = true,
        silent = true,
        expr = false,
      },
    },
    opts = {},
  },
  {
    "michaelb/sniprun",
    enabled = false,
    branch = "master",
    cmd = { "SnipRun", "SnipInfo" },
    -- do 'sh install.sh 1' if you want to force compile locally
    -- (instead of fetching a binary from the github release). Requires Rust >= 1.65
    build = "sh install.sh",
    config = function()
      require("sniprun").setup({
        selected_interpreters = { "Python3_fifo" }, --# use those instead of the default for the current filetype
        repl_enable = { "Python3_fifo" }, --# enable REPL-like behavior for the given interpreters
        repl_disable = {}, --# disable REPL-like behavior for the given interpreters

        interpreter_options = { --# interpreter-specific options, see doc / :SnipInfo <name>
          --# use the interpreter name as key
          GFM_original = {
            use_on_filetypes = { "markdown.pandoc" }, --# the 'use_on_filetypes' configuration key is
            --# available for every interpreter
          },
          Python3_original = {
            error_truncate = "auto", --# Truncate runtime errors 'long', 'short' or 'auto'
            --# the hint is available for every interpreter
            --# but may not be always respected
          },
          Go_original = {
            compiler = "gccgo",
          },
        },

        --# you can combo different display modes as desired and with the 'Ok' or 'Err' suffix
        --# to filter only sucessful runs (or errored-out runs respectively)
        display = {
          -- "Classic", --# display results in the command-line  area
          "VirtualTextOk", --# display ok results as virtual text (multiline is shortened)

          -- "VirtualText",             --# display results as virtual text
          -- "TempFloatingWindow",      --# display results in a floating window
          -- "LongTempFloatingWindow",  --# same as above, but only long results. To use with VirtualText[Ok/Err]
          "Terminal", --# display results in a vertical split
          -- "TerminalWithCode",        --# display results and code history in a vertical split
          "NvimNotify", --# display with the nvim-notify plugin
          -- "Api"                      --# return output to a programming interface
        },

        live_display = { "VirtualTextOk" }, --# display mode used in live_mode

        display_options = {
          terminal_scrollback = vim.o.scrollback, --# change terminal display scrollback lines
          terminal_line_number = false, --# whether show line number in terminal window
          terminal_signcolumn = false, --# whether show signcolumn in terminal window
          terminal_position = "vertical", --# or "horizontal", to open as horizontal split instead of vertical split
          terminal_width = 35, --# change the terminal display option width (if vertical)
          terminal_height = 20, --# change the terminal display option height (if horizontal)
          notification_timeout = 5, --# timeout for nvim_notify output
        },

        --# You can use the same keys to customize whether a sniprun producing
        --# no output should display nothing or '(no output)'
        show_no_output = {
          -- "Classic",
          "TempFloatingWindow", --# implies LongTempFloatingWindow, which has no effect on its own
          "NvimNotify", --# display with the nvim-notify plugin
        },

        --# customize highlight groups (setting this overrides colorscheme)
        --# any parameters of nvim_set_hl() can be passed as-is
        snipruncolors = {
          SniprunVirtualTextOk = { bg = "#66eeff", fg = "#000000", ctermbg = "Cyan", ctermfg = "Black" },
          SniprunFloatingWinOk = { fg = "#66eeff", ctermfg = "Cyan" },
          SniprunVirtualTextErr = { bg = "#881515", fg = "#000000", ctermbg = "DarkRed", ctermfg = "Black" },
          SniprunFloatingWinErr = { fg = "#881515", ctermfg = "DarkRed", bold = true },
        },

        live_mode_toggle = "off", --# live mode toggle, see Usage - Running for more info

        --# miscellaneous compatibility/adjustement settings
        inline_messages = true, --# boolean toggle for a one-line way to display messages
        --# to workaround sniprun not being able to display anything

        borders = "single", --# display borders around floating windows
        --# possible values are 'none', 'single', 'double', or 'shadow'
      })
    end,
  },
  {
    "danymat/neogen",
    cmd = "Neogen",
    dependencies = { "L3MON4D3/LuaSnip", version = "v2.*" },
    keys = {
      {
        "<leader>ne",
        function()
          require("neogen").generate()
        end,
        desc = "Neogen Comment",
      },
    },
    opts = {
      snippet_engine = "luasnip",
      input_after_comment = false,
      languages = {
        python = {
          template = {
            annotation_convention = "google_docstrings",
          },
        },
        go = {
          template = {
            annotation_convention = "godoc",
          },
        },
        lua = {
          template = {
            annotation_convention = "emmylua",
          },
        },
      },
    },
  },
}
