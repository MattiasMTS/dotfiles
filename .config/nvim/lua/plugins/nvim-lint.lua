return {
  {
    "mfussenegger/nvim-lint",
    event = { "BufWritePost", "BufReadPost" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        terraform = { "tofu", "tflint" },
        tf = { "tofu", "tflint" },
        ["terraform-vars"] = { "tofu", "tflint" },
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
