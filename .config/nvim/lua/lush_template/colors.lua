local lush = require("lush")
local hsl = lush.hsl
local transparent = true

local colors = {
  bg = hsl(221, 13, 12),
  bg_lighter = hsl(220, 13, 15),
  bg_dark = hsl(220, 13, 11),
  fg = hsl(220, 14, 82),
  gray1 = hsl(220, 10, 25),
  gray2 = hsl(220, 12, 42),
  gray3 = hsl(220, 10, 65),
  blue = hsl(210, 45, 72),
  cyan = hsl(190, 40, 65),
  green = hsl(140, 30, 65),
  red = hsl(355, 45, 65),
  yellow = hsl(35, 40, 65),
  purple = hsl(280, 35, 65),
}

	-- stylua: ignore
return lush(function(injected_symbols)
	return {

    -- Core syntax
    Normal { fg = colors.fg, bg = transparent and "" or colors.bg},
    Comment { fg = colors.gray2, gui = "italic" },
    Statement { fg = colors.blue, gui = "bold" },
    Identifier { fg = colors.fg },
    Type { fg = colors.cyan },
    Constant { fg = colors.purple },
    String { fg = colors.green },
    Special { fg = colors.gray3 },
    Function { fg = colors.blue.lighten(5) },
    NormalFloat { bg = colors.bg_lighter },
    FloatBorder { fg = colors.gray1 },

    -- Editor UI
    LineNr { fg = colors.gray1 },
    SignColumn { bg = colors.bg },
    ColorColumn { bg = colors.bg_lighter },
    StatusLine { bg = colors.gray1, fg = colors.fg },
    StatusLineNC { bg = colors.bg, fg = colors.gray2 },
    VertSplit { fg = colors.gray1 },
    Pmenu { bg = colors.bg_lighter, fg = colors.fg },
    PmenuSel { bg = colors.gray1, fg = colors.fg },

    -- Search/Selection
    Search { bg = colors.yellow.darken(40), fg = colors.fg },
    Visual { bg = colors.gray1 },
    CursorLine { bg = colors.bg_lighter },

    -- Git highlights
    DiffAdd { fg = colors.green.darken(10) },
    DiffChange { fg = colors.yellow.darken(10) },
    DiffDelete { fg = colors.red.darken(10) },

    -- Treesitter context
    TreesitterContext { bg = colors.bg_lighter },
    TreesitterContextLineNumber { fg = colors.gray2 },

    -- Neo-tree
    NeoTreeNormal { bg = colors.bg_dark },
    NeoTreeNormalNC { bg = transparent and "" or colors.bg },

    -- Dropbar
    DropBarCurrentContext { fg = colors.gray3 },

    -- LSP
    DiagnosticError { fg = colors.red },
    DiagnosticWarn { fg = colors.yellow },
    DiagnosticInfo { fg = colors.cyan },
    DiagnosticHint { fg = colors.gray3 },
    LspReferenceText { bg = colors.gray1 },
    LspReferenceRead { bg = colors.gray1 },
    LspReferenceWrite { bg = colors.gray1 },

    -- Inline hints
    LspCodeLens { fg = colors.gray2, gui = "italic" },
    LspInlayHint { fg = colors.gray2, gui = "italic" },
	}
end)
