return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost" },
    config = function()
      require("lint").linters_by_ft = {
        terraform = { "terraform_validate", "trivy", "tflint" },
        tf = { "terraform_validate", "trivy", "tflint" },
        ["terraform-vars"] = { "terraform_validate", "tfsec", "tflint" },
        dockerfile = { "hadolint" },
        go = { "golangcilint" },
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
