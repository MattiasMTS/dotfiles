return {
  {
    "OXY2DEV/markview.nvim",
    enabled = false,
    ft = { "markdown", "codecompanion" },
    dependencies = {
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("markview").setup({
        -- Uses this feature on normal mode
        previews = {
          modes = { "n", "i", "no", "c" },
          hybrid_modes = { "n", "i" },

          -- This is nice to have
          callbacks = {
            on_enable = function(_, win)
              vim.wo[win].conceallevel = 2
              vim.wo[win].concealcursor = "c"
            end,
          },
        },
      })
    end,
  },
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "echasnovski/mini.icons" },
    ft = { "markdown", "codecompanion" },
    -- TODO: checkout connecting this to obsidian.nvim
    opts = {
      completions = {
        blink = { enabled = true },
        lsp = { enabled = true },
      },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    cmd = { "MarkdownPreview", "MarkdownPreviewToggle" },
    opts = {},
    keys = {
      { "<leader>md", "<cmd>MarkdownPreviewToggle<CR>" },
    },
  },
}
