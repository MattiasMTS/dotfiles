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
    formatters_by_ft = {
      python = { "ruff_organize_imports", "ruff_format" },
      terraform = { "terraform_fmt" },
      tf = { "terraform_fmt" },
      ["terraform-vars"] = { "terraform_fmt" },
      go = { "gofumpt", "goimports", "golines" },
      javascript = { "prettier", name = "dprint", lsp_format = "fallback" },
      json = { "prettier", stop_on_first = true, name = "dprint" },
      jsonc = { "prettier", stop_on_first = true, name = "dprint" },
      lua = { "stylua" },
      kotlin = { "ktfmt" },
      nix = { "nixfmt" },
      sql = { "sqlfmt" },
    },
    formatters = {
      golines = {
        prepend_args = {
          "--base-formatter=gofumpt",
          "--ignore-generated",
          "--tab-len=1",
          "--max-len=120",
        },
      },
      gofumpt = {
        prepend_args = { "-extra", "-w", "$FILENAME" },
        stdin = false,
      },
      goimports = {
        args = { "-srcdir", "$FILENAME" },
      },
    },
  },
}
