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
      go = { "gofumpt", "golines" },
      javascript = { "prettier", lsp_format = "fallback" },
      typescript = { "prettier", lsp_format = "fallback" },
      typescriptreact = { "prettier", lsp_format = "fallback" },
      json = { "prettier", stop_on_first = true },
      jsonc = { "prettier", stop_on_first = true },
      lua = { "stylua" },
      nix = { "nixfmt" },
    },
    formatters = {
      golines = {
        prepend_args = { "--max-len=120", "--base-formatter=gofumpt" },
      },
    },
  },
}
