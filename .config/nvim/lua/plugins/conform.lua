return {
  "stevearc/conform.nvim",
  enabled = true,
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  init = function()
    vim.g.autoformat = true
  end,
  opts = {
    default_format_opts = {
      lsp_fallback = true,
      timeout_ms = 500,
    },
    format_on_save = {},
    --
    formatters_by_ft = {
      python = { "ruff_organize_imports", "ruff_format" },
      terraform = { "tofu_fmt" },
      tf = { "tofu_fmt" },
      ["terraform-vars"] = { "tofu_fmt" },
      go = { "gofumpt", "goimports", "golines" },
      javascript = { "oxfmt", lsp_format = "fallback" },
      typescript = { "oxfmt", lsp_format = "fallback" },
      typescriptreact = { "oxfmt", lsp_format = "fallback" },
      html = { "oxfmt", lsp_format = "fallback" },
      json = { "oxfmt", stop_on_first = true },
      jsonc = { "oxfmt", stop_on_first = true },
      lua = { "stylua" },
      nix = { "nixfmt" },
      toml = { "oxfmt", stop_on_first = true },
      bash = { "shfmt" },
    },
    formatters = {
      golines = {
        prepend_args = { "--max-len=120", "--base-formatter=gofumpt" },
      },
    },
  },
}
