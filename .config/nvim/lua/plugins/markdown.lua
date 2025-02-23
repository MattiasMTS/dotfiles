return {
  {
    "OXY2DEV/markview.nvim",
    enabled = false,
    ft = "markdown",
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
    "iamcco/markdown-preview.nvim",
    keys = {
      { "n", "<leader>md", "<cmd>MarkdownPreviewToggle<CR>" },
    },
  },
}
