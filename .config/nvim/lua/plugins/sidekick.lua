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
        },
        ---@type table<string, sidekick.cli.Config|{}>
        tools = {
          claude = {
            cmd = { "claude", "--ide" },
          },
          amp = {
            cmd = { "amp", "--ide" },
          },
        },
      },
    },
    keys = {
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle({ name = "amp" })
        end,
        desc = "Toggle Amp",
        mode = { "n", "t", "x" },
      },
      {
        "<leader>ac",
        function()
          require("sidekick.cli").toggle({ name = "claude" })
        end,
        desc = "Toggle Claude",
        mode = { "n", "t", "x" },
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
    opts = {
      log_level = "error",
      diff_opts = {
        vertical_split = true,
        open_in_current_tab = false,
      },
    },
    keys = {
      -- Diff management
      { "<leader>ay", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>ad", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  },
  {
    "sourcegraph/amp.nvim",
    branch = "main",
    lazy = false,
    opts = {
      auto_start = true,
      log_level = "info",
    },
  },
}
