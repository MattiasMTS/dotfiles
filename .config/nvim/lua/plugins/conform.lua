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
      terraform = { "tofu_fmt" },
      tf = { "tofu_fmt" },
      ["terraform-vars"] = { "tofu_fmt" },
      go = { "gofumpt", "goimports" },
      javascript = { "prettier", name = "dprint", lsp_format = "fallback" },
      json = { "prettier", stop_on_first = true, name = "dprint" },
      jsonc = { "prettier", stop_on_first = true, name = "dprint" },
      lua = { "stylua" },
      nix = { "nixfmt" },
      -- sql = { "sqlmesh_format" },
    },
    formatters = {
      -- sqlmesh_format = {
      --   command = "sqlmesh",
      --   args = { "format", "$FILENAME" },
      --   stdin = false,
      -- },
      -- golines = {
      --   prepend_args = {
      --     "--base-formatter=gofumpt",
      --     "--ignore-generated",
      --     "--tab-len=1",
      --     "--max-len=120",
      --   },
      -- },
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
