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

        -- Neo-tree
        hl.NeoTreeNormal = { fg = c.fg, bg = c.bg_hard }
        hl.NeoTreeNormalNC = { fg = c.fg, bg = c.bg_hard }
        hl.NeoTreeEndOfBuffer = { fg = c.bg_hard, bg = c.bg_hard }
        hl.NeoTreeRootName = { fg = c.primary, bold = true }
        hl.NeoTreeDirectoryName = { fg = c.blue }
        hl.NeoTreeDirectoryIcon = { fg = c.blue }
        hl.NeoTreeFileName = { fg = c.fg }
        hl.NeoTreeFileIcon = { fg = c.fg }
        hl.NeoTreeGitAdded = { fg = c.diff.add }
        hl.NeoTreeGitConflict = { fg = c.dull_yellow }
        hl.NeoTreeGitDeleted = { fg = c.diff.delete }
        hl.NeoTreeGitIgnored = { fg = c.comment }
        hl.NeoTreeGitModified = { fg = c.diff.change }
        hl.NeoTreeGitUnstaged = { fg = c.diff.change }
        hl.NeoTreeGitUntracked = { fg = c.dull_yellow }
        hl.NeoTreeGitStaged = { fg = c.diff.add }
        hl.NeoTreeIndentMarker = { fg = c.fg_soft }
        hl.NeoTreeExpander = { fg = c.fg_soft }
        hl.NeoTreeWinSeparator = { fg = c.bg_hard, bg = c.bg_hard }
        hl.NeoTreeCursorLine = { bg = c.line }

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

        -- Snacks.nvim
        hl.SnacksNormal = { fg = c.fg, bg = c.bg_hard }
        hl.SnacksBorder = { fg = c.dull_blue, bg = c.bg_hard }
        hl.SnacksTitle = { fg = c.primary, bold = true }
        hl.SnacksBackdrop = { bg = c.bg_hard }
        hl.SnacksNotifierInfo = { fg = c.diag.info }
        hl.SnacksNotifierWarn = { fg = c.diag.warning }
        hl.SnacksNotifierError = { fg = c.diag.error }
        hl.SnacksNotifierDebug = { fg = c.comment }
        hl.SnacksNotifierTrace = { fg = c.magenta }
        hl.SnacksNotifierIconInfo = { fg = c.diag.info }
        hl.SnacksNotifierIconWarn = { fg = c.diag.warning }
        hl.SnacksNotifierIconError = { fg = c.diag.error }
        hl.SnacksNotifierIconDebug = { fg = c.comment }
        hl.SnacksNotifierIconTrace = { fg = c.magenta }
        hl.SnacksDashboardNormal = { fg = c.fg, bg = "NONE" }
        hl.SnacksDashboardHeader = { fg = c.primary }
        hl.SnacksDashboardFooter = { fg = c.comment }
        hl.SnacksDashboardKey = { fg = c.yellow }
        hl.SnacksDashboardIcon = { fg = c.blue }
        hl.SnacksDashboardDesc = { fg = c.fg }
        hl.SnacksIndent = { fg = c.bg_soft }
        hl.SnacksIndentScope = { fg = c.dull_blue }

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
    enabled = true,
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
