return {
  {
    "HoNamDuong/hybrid.nvim",
    name = "hybrid",
    priority = 1000,
    lazy = false,
    enabled = false,
    opts = {
      transparent = false,
      italic = { strings = false, emphasis = false, comments = true, folds = false },
      overrides = function(hl, c)
        -- gitglame
        hl.GitSignsCurrentLineBlame = { fg = c.comment }

        hl.ColorColumn = { bg = c.bg_soft }
        hl.LineNr = { fg = c.fg_soft }

        -- inlay hints
        hl.LspInlayHint = { fg = c.comment, bg = "NONE", italic = true }

        -- cmp
        hl.BlinkCmpMenu = { bg = c.bright_black }
        hl.BlinkCmpMenuBorder = { fg = c.dull_blue, bg = c.bg_hard }
        hl.BlinkCmpMenuSelection = { bg = c.teal }
      end,
    },
  },
  {
    "olimorris/onedarkpro.nvim",
    priority = 1000,
    lazy = false,
    enabled = false,
    opts = {},
  },
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    lazy = false,
    enabled = true,
    opts = {
      styles = {
        comments = { italic = true },
        keywords = {},
        functions = {},
        variables = {},
      },
      lualine_bold = true,
    },
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    enabled = false,
    opts = {
      flavour = "macchiato",
      transparent_background = false,
      term_colors = true,
      compile_path = vim.fn.stdpath("cache") .. "/catppuccin",
      dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
      },
      styles = {
        comments = {},
        conditionals = { "bold" },
        functions = { "bold" },
        operators = { "bold" },
        keywords = { "bold" },
        loops = { "bold" },
        strings = {},
        variables = {},
        numbers = {},
        booleans = { "bold" },
        properties = {},
        types = {},
      },
      default_integrations = true,
      integrations = {
        treesitter = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "underline" },
            hints = { "underline" },
            warnings = { "underline" },
            information = { "underline" },
          },
          virtual_text = {
            errors = {},
            hints = {},
            warnings = {},
            information = {},
          },
        },
        blink_cmp = true,
        dropbar = { enabled = true, color_mode = true },
        gitsigns = true,
        mini = { enabled = true, indentscope_color = "" },
        neotree = { enabled = true, show_root = true, transparent_panel = true },
        render_markdown = true,
        markdown = true,
        semantic_tokens = true,
        fzf = true,
        treesitter_context = true,
        grug_far = true,
      },
      highlight_overrides = {
        all = function(cp)
          return {
            -- For base configs
            NormalFloat = { fg = cp.text, bg = cp.mantle },
            FloatBorder = { fg = cp.mantle, bg = cp.mantle },
            CursorLineNr = { fg = cp.green },

            -- For native lsp configs
            -- testing out undercurl instead of sideline
            DiagnosticVirtualTextError = { bg = cp.none },
            DiagnosticVirtualTextWarn = { bg = cp.none },
            DiagnosticVirtualTextInfo = { bg = cp.none },
            DiagnosticVirtualTextHint = { bg = cp.none },
            LspInfoBorder = { link = "FloatBorder" },

            -- For blink
            Pmenu = { fg = cp.overlay2, bg = cp.base },
            PmenuBorder = { fg = cp.surface1, bg = cp.base },
            PmenuSel = { bg = cp.green, fg = cp.base },
            BlinkCmpKind = { fg = cp.overlay2 },
            BlinkCmpKindMatch = { fg = cp.blue, style = { "bold" } },
            BlinkCmpDoc = { link = "NormalFloat" },
            BlinkCmpDocBorder = { fg = cp.mantle, bg = cp.mantle },

            -- For neo-tree
            NeoTreeNormal = { bg = cp.mantle }, -- Set a darker background for Neo-tree
            NeoTreeNormalNC = { bg = cp.mantle }, -- Set a darker background for non-current Neo-tree window
            NeoTreeEndOfBuffer = { bg = cp.mantle }, -- Set a darker background for end of buffer in Neo-tree

            -- For treesitter
            ["@keyword.return"] = { fg = cp.pink, style = {} },
            ["@error.c"] = { fg = cp.none, style = {} },
            ["@error.cpp"] = { fg = cp.none, style = {} },
          }
        end,
      },
    },
  },
}
