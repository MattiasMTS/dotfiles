return {
  {
    "nvim-treesitter/nvim-treesitter",
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-context",
        opts = {
          -- Avoid the sticky context from growing a lot.
          max_lines = 3,
          -- Match the context lines to the source code.
          multiline_threshold = 1,
          -- Disable it when the window is too small.
          min_window_height = 20,
        },
      },
      { "ngalaiko/tree-sitter-go-template", ft = "go" },
    },
    version = false,
    branch = "main",
    cmd = { "TSUpdateSync", "TSUpdate", "TSInstall" },
    event = { "VeryLazy" },
    opts = {
      indent = { enable = false },
      highlight = { enable = true },
      auto_install = false,
    },
  },
}
