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

        -- kotlin
        kotlin = { "ktlint" },

        -- dockerfile
        dockerfile = { "hadolint" },

        -- go
        -- go = { "golangci_lint", "gosec" },

        -- TODO: fix this
        -- github actions
        -- ["yaml.ghactions"] = { "actionlint" },

        -- fileMatch = { "**/.github/workflows/*.yml", "**/.github/workflows/*.yaml", "**/.gitea/workflows/*.yml", "**/.gitea/workflows/*.yaml", "**/.forgejo/workflows/*.yml", "**/.forgejo/workflows/*.yaml" },
      },
    },
  },
}
