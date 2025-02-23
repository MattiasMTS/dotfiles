return {
  "stevearc/conform.nvim",
  enabled = true,
  event = { "BufWritePre" },
  cmd = { "ConformInfo" },
  opts = {
    default_format_opts = {
      lsp_fallback = true,
      timeout_ms = 500,
    },
    formatters_by_ft = {
      python = { "isort", "black" },
      terraform = { "terraform_fmt" },
      tf = { "terraform_fmt" },
      ["terraform-vars"] = { "terraform_fmt" },
      hcl = { "terragrunt_hclfmt", "packer_fmt" },
      go = { "gofumpt", "goimports" },
      sql = { "sqlfmt" },
    },
    formatters = {
      black = {
        exe = "black",
        args = { "--quiet", "-", "--fast", "--line-length", "80" },
        stdin = true,
      },
      isort = {
        exe = "isort",
        args = { "-", "--quiet", "--profile", "black" },
        stdin = true,
      },
      sqlfmt = {
        exe = "sqlfmt",
        stdin = true,
        args = { "-", "--fast", "--line-length", "120", "--quiet", "--no-progressbar" },
      },
      gofumpt = {
        prepend_args = { "-extra", "-w", "$FILENAME" },
        stdin = false,
      },
    },
  },
}
