return {
  {
    "mfussenegger/nvim-lint",
    lazy = true,
    opts = {
      events = { "BufWritePost", "BufReadPost", "InsertLeave" },
      linters_by_ft = {
        -- terraform
        terraform = { "terraform_validate", "trivy", "tflint" },
        tf = { "terraform_validate", "trivy", "tflint" },
        ["terraform-vars"] = { "terraform_validate", "tfsec", "tflint" },

        -- dockerfile
        dockerfile = { "hadolint" },

        -- go
        go = { "golangci-lint", "gosec" },

        -- bash
        sh = { "shellcheck" },
        bash = { "shellcheck" },

        -- nix
        nix = { "nix" },

        -- python
        python = { "ruff" },

        -- yaml
        yaml = { "yamllint" },

        -- markdown
        markdown = { "markdownlint" },

        -- github actions
        -- ghaction = { "actionlint" },
      },
    },
  },
}
