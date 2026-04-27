return {
  {
    "HoNamDuong/hybrid.nvim",
    name = "hybrid",
    priority = 1000,
    lazy = false,
    enabled = true,
    opts = {
      transparent = true,
      italic = { strings = false, emphasis = false, comments = false, folds = false },
      overrides = function(hl, c)
        -- Git blame
        hl.GitSignsCurrentLineBlame = { fg = c.comment }

        -- UI
        hl.ColorColumn = { bg = c.bg_soft }
        hl.LineNr = { fg = c.fg_soft }

        -- Diff
        local hybrid_utils = require("hybrid.utils")
        hl.DiffAdd = { bg = hybrid_utils.darken(c.diff.add, 0.3, c.bg) }
        hl.DiffChange = { bg = hybrid_utils.darken(c.diff.change, 0.3, c.bg) }
        hl.DiffDelete = { bg = hybrid_utils.darken(c.diff.delete, 0.3, c.bg) }
        hl.DiffText =
          { bg = hybrid_utils.darken(c.diff.text, 0.5, hybrid_utils.darken(c.diff.change, 0.3, c.bg)), bold = true }
        hl.DiffToolDelLine = { bg = hybrid_utils.darken(c.diff.delete, 0.2, c.bg) }
        hl.DiffToolDelText = { bg = hybrid_utils.darken(c.diff.delete, 0.45, c.bg), bold = true }
        hl.DiffToolAddLine = { bg = hybrid_utils.darken(c.diff.add, 0.2, c.bg) }
        hl.DiffToolAddText = { bg = hybrid_utils.darken(c.diff.add, 0.45, c.bg), bold = true }

        -- LSP inlay hints
        hl.LspInlayHint = { fg = c.comment, bg = "NONE", italic = true }

        -- Blink.cmp
        hl.BlinkCmpMenu = { bg = c.bright_black }
        hl.BlinkCmpMenuBorder = { fg = c.dull_blue, bg = c.bg_hard }
        hl.BlinkCmpMenuSelection = { bg = c.teal }
        hl.BlinkCmpDoc = { bg = c.bg_hard }
        hl.BlinkCmpDocBorder = { fg = c.dull_blue, bg = c.bg_hard }
        hl.BlinkCmpDocSeparator = { fg = c.dull_blue, bg = c.bg_hard }
        hl.BlinkCmpLabel = { fg = c.fg }
        hl.BlinkCmpLabelMatch = { fg = c.match, bold = true }
        hl.BlinkCmpLabelDeprecated = { fg = c.fg_soft, strikethrough = true }
        hl.BlinkCmpGhostText = { fg = c.comment }
        hl.BlinkCmpSignatureHelp = { bg = c.bg_hard }
        hl.BlinkCmpSignatureHelpBorder = { fg = c.dull_blue, bg = c.bg_hard }

        -- FzfLua
        hl.FzfLuaNormal = { fg = c.fg, bg = c.bg_hard }
        hl.FzfLuaBorder = { fg = c.dull_blue, bg = c.bg_hard }
        hl.FzfLuaTitle = { fg = c.primary, bold = true }
        hl.FzfLuaPreviewNormal = { fg = c.fg, bg = c.bg_hard }
        hl.FzfLuaPreviewBorder = { fg = c.dull_blue, bg = c.bg_hard }
        hl.FzfLuaPreviewTitle = { fg = c.green, bold = true }
        hl.FzfLuaCursorLine = { bg = c.line }
        hl.FzfLuaScrollBorderEmpty = { fg = c.dull_blue, bg = c.bg_hard }
        hl.FzfLuaScrollBorderFull = { fg = c.primary, bg = c.bg_hard }
        hl.FzfLuaHelpNormal = { fg = c.fg, bg = c.bg_hard }
        hl.FzfLuaHelpBorder = { fg = c.dull_blue, bg = c.bg_hard }
        hl.FzfLuaHeaderBind = { fg = c.green }
        hl.FzfLuaHeaderText = { fg = c.yellow }
        hl.FzfLuaFzfMatch = { fg = c.match }

        -- Treesitter Context
        hl.TreesitterContext = { bg = c.line }
        hl.TreesitterContextLineNumber = { fg = c.fg_soft, bg = c.line }
        hl.TreesitterContextSeparator = { fg = c.bg_soft }
        hl.TreesitterContextBottom = { underline = true, sp = c.bg_soft }

        -- Mini
        hl.MiniFilesNormal = { fg = c.fg, bg = c.bg_hard }
        hl.MiniFilesBorder = { fg = c.dull_blue, bg = c.bg_hard }
        hl.MiniFilesBorderModified = { fg = c.dull_yellow, bg = c.bg_hard }
        hl.MiniFilesCursorLine = { bg = c.line }
        hl.MiniFilesDirectory = { fg = c.blue }
        hl.MiniFilesFile = { fg = c.fg }
        hl.MiniFilesTitle = { fg = c.primary, bold = true }
        hl.MiniFilesTitleFocused = { fg = c.primary, bold = true }
        hl.MiniHipatternsFixme = { fg = c.bg, bg = c.diag.error, bold = true }
        hl.MiniHipatternsHack = { fg = c.bg, bg = c.diag.warning, bold = true }
        hl.MiniHipatternsTodo = { fg = c.bg, bg = c.diag.hint, bold = true }
        hl.MiniHipatternsNote = { fg = c.bg, bg = c.diag.info, bold = true }
        hl.MiniIconsAzure = { fg = c.bright_blue }
        hl.MiniIconsBlue = { fg = c.blue }
        hl.MiniIconsCyan = { fg = c.cyan }
        hl.MiniIconsGreen = { fg = c.green }
        hl.MiniIconsGrey = { fg = c.fg_soft }
        hl.MiniIconsOrange = { fg = c.dull_yellow }
        hl.MiniIconsPurple = { fg = c.magenta }
        hl.MiniIconsRed = { fg = c.red }
        hl.MiniIconsYellow = { fg = c.yellow }

        -- Grug-far
        hl.GrugFarHelpHeader = { fg = c.primary, bold = true }
        hl.GrugFarHelpHeaderKey = { fg = c.yellow }
        hl.GrugFarInputLabel = { fg = c.green, bold = true }
        hl.GrugFarInputPlaceholder = { fg = c.comment }
        hl.GrugFarResultsHeader = { fg = c.primary }
        hl.GrugFarResultsMatch = { fg = c.bg, bg = c.match }
        hl.GrugFarResultsStats = { fg = c.comment }
        hl.GrugFarResultsLineNo = { fg = c.fg_soft }
        hl.GrugFarResultsLineColumn = { fg = c.fg_soft }
        hl.GrugFarResultsPath = { fg = c.blue }

        -- Render-markdown
        hl.RenderMarkdownH1Bg = { bg = c.line, bold = true }
        hl.RenderMarkdownH2Bg = { bg = c.line, bold = true }
        hl.RenderMarkdownH3Bg = { bg = c.line, bold = true }
        hl.RenderMarkdownH4Bg = { bg = c.line }
        hl.RenderMarkdownH5Bg = { bg = c.line }
        hl.RenderMarkdownH6Bg = { bg = c.line }
        hl.RenderMarkdownCode = { bg = c.line }
        hl.RenderMarkdownCodeInline = { bg = c.line }
        hl.RenderMarkdownBullet = { fg = c.blue }
        hl.RenderMarkdownQuote = { fg = c.blue }
        hl.RenderMarkdownDash = { fg = c.bg_soft }
        hl.RenderMarkdownLink = { fg = c.magenta }
        hl.RenderMarkdownTableHead = { fg = c.primary }
        hl.RenderMarkdownTableRow = { fg = c.fg }
        hl.RenderMarkdownCheckedBox = { fg = c.green }
        hl.RenderMarkdownUncheckedBox = { fg = c.fg_soft }

        -- Tiny-inline-diagnostics
        hl.TinyInlineDiagnosticVirtualTextError = { fg = c.diag.error }
        hl.TinyInlineDiagnosticVirtualTextWarn = { fg = c.diag.warning }
        hl.TinyInlineDiagnosticVirtualTextInfo = { fg = c.diag.info }
        hl.TinyInlineDiagnosticVirtualTextHint = { fg = c.diag.hint }
      end,
    },
  },
  {
    "folke/tokyonight.nvim",
    priority = 1000,
    lazy = false,
    enabled = false,
    opts = {
      style = "moon",
      styles = {
        comments = {},
        keywords = {},
        functions = {},
        variables = {},
      },
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
      transparent_background = true,
      compile_path = vim.fn.stdpath("cache") .. "/catppuccin",
      lsp_styles = {
        underlines = {
          errors = { "undercurl" },
          hints = { "undercurl" },
          warnings = { "undercurl" },
          information = { "undercurl" },
        },
      },
      styles = {
        comments = {},
        conditionals = {},
        functions = {},
        operators = {},
        keywords = {},
        loops = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
      },
      default_integrations = true,
      integrations = {
        treesitter = true,
        blink_cmp = true,
        gitsigns = true,
        mini = { enabled = true },
        neotree = { enabled = true, show_root = true, transparent_panel = true },
        render_markdown = true,
        markdown = true,
        semantic_tokens = true,
        fzf = true,
        treesitter_context = true,
        grug_far = true,
        snacks = true,
        which_key = true,
        notify = true,
      },
      highlight_overrides = {
        all = function(cp)
          return {
            -- For base configs
            -- NormalFloat = { fg = cp.text, bg = cp.mantle },
            -- FloatBorder = { fg = cp.mantle, bg = cp.mantle },
            -- CursorLineNr = { fg = cp.green },

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
