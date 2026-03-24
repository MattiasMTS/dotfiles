return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost" },
    config = function()
      local lint = require("lint")

      -- Fix golangci-lint working directory to find go.mod or .golangci.yml
      -- lint.linters.golangcilint.cwd = function(ctx)
      --   return vim.fs.root(ctx.filename, { "go.mod", ".golangci.yml" }) or vim.fn.getcwd()
      -- end

      lint.linters_by_ft = {
        terraform = { "terraform_validate", "tflint" },
        tf = { "terraform_validate", "tflint" },
        ["terraform-vars"] = { "terraform_validate", "tfsec", "tflint" },
        dockerfile = { "hadolint" },
        -- go = { "golangcilint" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        nix = { "nix" },
        python = { "ruff" },
        yaml = { "yamllint" },
        markdown = { "markdownlint" },
      }
    end,
  },
}
