return {
  -- sidekick.nvim for main workflow
  {
    "folke/sidekick.nvim",
    dependencies = { "coder/claudecode.nvim" },
    ---@class sidekick.Config
    opts = {
      nes = { enabled = false },
      cli = {
        mux = { backend = "tmux", enabled = false },
        win = {
          split = { width = 70 },
          layout = "right",
        },
        tools = {
          amp = {
            cmd = { "amp" },
          },
        },
      },
    },
    keys = {
      {
        "<c-space>",
        function()
          require("sidekick.cli").toggle()
        end,
        desc = "Sidekick Toggle",
        mode = { "n", "t", "i", "x" },
      },
      {
        "<leader>at",
        function()
          require("sidekick.cli").send({ msg = "{this}" })
        end,
        mode = { "x", "n" },
        desc = "Send This",
      },
      {
        "<leader>af",
        function()
          require("sidekick.cli").send({ msg = "{file}" })
        end,
        desc = "Send File",
      },
      {
        "<leader>as",
        function()
          require("sidekick.cli").send({ msg = "{selection}" })
        end,
        mode = { "x" },
        desc = "Send Visual Selection",
      },
      {
        "<leader>ap",
        function()
          require("sidekick.cli").prompt()
        end,
        mode = { "n", "x" },
        desc = "Select Prompt",
      },
    },
  },
  {
    "coder/claudecode.nvim",
    dev = true,
    ---@type ClaudeCodeConfig
    opts = {
      auto_start = true,
      log_level = "info",
      port_range = { min = 10000, max = 65535 },
      -- diff_opts = {
      --   provider = "inline",
      -- },
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
    enabled = true,
    dev = false,
    branch = "main",
    lazy = false,
    opts = {
      auto_start = true,
      log_level = "info",
    },
  },
}
