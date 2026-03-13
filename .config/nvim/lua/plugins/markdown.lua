return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.icons" },
    ft = { "markdown", "codecompanion" },
    -- TODO: checkout connecting this to obsidian.nvim with markdown-oxide lsp
    opts = {
      completions = {
        blink = { enabled = true },
        lsp = { enabled = true },
      },
    },
  },
  {
    "iamcco/markdown-preview.nvim",
    enabled = false,
    cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
    config = function()
      vim.cmd([[do FileType]])
    end,
    keys = {
      { "<leader>md", "<cmd>MarkdownPreviewToggle<CR>", ft = "markdown" },
    },
  },
}
