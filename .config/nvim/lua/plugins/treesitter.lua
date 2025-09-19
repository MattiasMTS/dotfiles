return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "main",
    version = false,
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
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "nix",
        "go",
        "gomod",
        "gowork",
        "gosum",
        "gotmpl",
        "templ",
        "superhtml",
        "helm",
        "bash",
        "dockerfile",
        "graphql",
        "html",
        "java",
        "javascript",
        "json",
        "json5",
        "jsonc",
        "lua",
        "markdown",
        "markdown_inline",
        "python",
        "jinja",
        "jinja_inline",
        "rust",
        "toml",
        "tsx",
        "typescript",
        "vim",
        "vimdoc",
        "yaml",
        "terraform",
        "hcl",
        "proto",
        "kotlin",
        "sql",
        "regex",
      },
      indent = { enable = true, disable = { "yaml" } },
      highlight = { enable = true },
      folds = { enable = false },
      auto_install = false,
    },
    config = function(_, opts)
      require("nvim-treesitter").setup(opts)
      require("nvim-treesitter").install(opts.ensure_installed)
    end,
  },
}
