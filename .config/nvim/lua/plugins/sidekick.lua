return {
  -- claudecode.nvim provides MCP server + diff accept/deny
  {
    "coder/claudecode.nvim",
    opts = {
      diff_opts = {
        auto_close_on_accept = true,
        vertical_split = false,
        open_in_current_tab = true,
        keep_terminal_focus = false,
      },
    },
    keys = {
      {
        "<leader>aS",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file to Claude (tree)",
        ft = { "NvimTree", "neo-tree", "oil" },
      },
      { "<C-y>", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<C-n>", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
  },
  -- sidekick.nvim for main workflow
  {
    "folke/sidekick.nvim",
    dependencies = {
      "coder/claudecode.nvim",
    },
    enabled = true,
    ---@class sidekick.Config
    opts = {
      nes = { enabled = false },
      cli = {
        mux = { backend = "tmux", enabled = true },
        win = {
          split = { width = 70 },
        },
        ---@type table<string, sidekick.cli.Config|{}>
        tools = {
          claude = {
            cmd = { "claude", "--continue", "--ide" },
          },
        },
      },
    },
    keys = {
      {
        "<leader>aa",
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
}
