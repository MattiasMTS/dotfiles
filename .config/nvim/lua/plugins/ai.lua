return {
  {
    "coder/claudecode.nvim",
    event = "VeryLazy",
    opts = {
      auto_start = true,
      log_level = "info",
      port_range = { min = 10000, max = 65535 },
    },
    keys = {
      -- Diff management
      { "<leader>ay", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff hunk" },
      { "<leader>aY", "<cmd>ClaudeCodeDiffAcceptAll<cr>", desc = "Accept all diffs" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff hunk" },
      { "<leader>aD", "<cmd>ClaudeCodeDiffDenyAll<cr>", desc = "Deny all diffs" },
    },
  },
  {
    "sourcegraph/amp.nvim",
    -- lazy = false,
    event = "VeryLazy",
    branch = "main",
    opts = {
      auto_start = true,
      log_level = "info",
    },
  },
}
