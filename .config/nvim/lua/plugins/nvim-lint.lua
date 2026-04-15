return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        terraform = { "tofu_validate", "tflint" },
        tf = { "tofu_validate", "tflint" },
        ["terraform-vars"] = { "tofu_validate", "tflint" },
        dockerfile = { "hadolint" },
        sh = { "shellcheck" },
        bash = { "shellcheck" },
        nix = { "nix" },
        python = { "ruff" },
        yaml = { "yamllint" },
      }
    end,
  },
}
