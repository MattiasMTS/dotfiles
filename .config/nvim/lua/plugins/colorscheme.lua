return {
  {
    "HoNamDuong/hybrid.nvim",
    name = "hybrid",
    priority = 1000,
    lazy = false,
    enabled = true,
    opts = {
      transparent = true,
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
    "folke/tokyonight.nvim",
    priority = 1000,
    lazy = false,
    enabled = false,
  },
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    lazy = false,
    enabled = false,
    opts = {
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      transparent_background = false,
      show_end_of_buffer = true,
      term_colors = true,
      compile_path = vim.fn.stdpath("cache") .. "/catppuccin",
      dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
      },
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
        },
        cmp = true,
        dashboard = true,
        dropbar = { enabled = false, color_mode = true },
        fern = false,
        fidget = false,
        flash = false,
        gitgutter = false,
        gitsigns = true,
        harpoon = false,
        headlines = false,
        hop = false,
        illuminate = true,
        indent_blankline = { enabled = false, colored_indent_levels = false },
        leap = false,
        lightspeed = false,
        lsp_saga = false,
        lsp_trouble = false,
        markdown = true,
        mason = true,
        mini = false,
        navic = { enabled = true },
        neogit = false,
        neotest = false,
        neotree = { enabled = true, show_root = true, transparent_panel = false },
        noice = true,
        notify = true,
        nvimtree = false,
        overseer = false,
        pounce = false,
        rainbow_delimiters = true,
        render_markdown = true,
        sandwich = false,
        semantic_tokens = true,
        telescope = { enabled = true },
        treesitter_context = true,
      },
      highlight_overrides = {
        all = function(cp)
          return {
            -- For base configs
            NormalFloat = { fg = cp.text, bg = cp.mantle },
            FloatBorder = {
              fg = cp.mantle,
              bg = cp.mantle,
            },

            -- testing out undercurl
            DiagnosticVirtualTextError = { bg = cp.none },
            DiagnosticVirtualTextWarn = { bg = cp.none },
            DiagnosticVirtualTextInfo = { bg = cp.none },
            DiagnosticVirtualTextHint = { bg = cp.none },

            -- For native lsp configs
            LspInfoBorder = { link = "FloatBorder" },

            -- For mason.nvim
            MasonNormal = { link = "NormalFloat" },

            -- For nvim-cmp
            Pmenu = { fg = cp.overlay2, bg = cp.base },
            PmenuBorder = { fg = cp.surface1, bg = cp.base },
            PmenuSel = { bg = cp.green, fg = cp.base },
            CmpItemAbbr = { fg = cp.overlay2 },
            CmpItemAbbrMatch = { fg = cp.blue, style = { "bold" } },
            CmpDoc = { link = "NormalFloat" },
            CmpDocBorder = {
              fg = cp.mantle,
              bg = cp.mantle,
            },

            -- For nvim-notify
            NotifyBackground = { bg = cp.base },

            -- For neo-tree
            NeoTreeNormal = { bg = cp.mantle }, -- Set a darker background for Neo-tree
            NeoTreeNormalNC = { bg = cp.mantle }, -- Set a darker background for non-current Neo-tree window
            NeoTreeEndOfBuffer = { bg = cp.mantle }, -- Set a darker background for end of buffer in Neo-tree

            -- For trouble.nvim
            TroubleNormal = { bg = cp.base },
            TroubleNormalNC = { bg = cp.base },

            -- For treesitter
            ["@keyword.return"] = { fg = cp.pink, style = {} },
            ["@error.c"] = { fg = cp.none, style = {} },
            ["@error.cpp"] = { fg = cp.none, style = {} },
          }
        end,
      },
    },
  },
  {
    "rktjmp/lush.nvim",
    cmd = "Lushify",
    lazy = true,
  },
}
