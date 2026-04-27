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
  {
    "milanglacier/minuet-ai.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      -- Use Minuet's LSP inline-completion frontend for Copilot-style virtual text.
      lsp = {
        enabled_ft = { "*" },
        completion = { enable = false },
        inline_completion = {
          enable = true,
          enabled_auto_trigger_ft = { "*" },
        },
      },
      provider = "openai_fim_compatible",
      n_completions = 1,
      context_window = 512,
      debounce = 60,
      throttle = 0,
      request_timeout = 4,
      provider_options = {
        openai_fim_compatible = {
          api_key = function()
            return "ollama"
          end,
          name = "ollama",
          end_point = "http://127.0.0.1:11434/v1/completions",
          model = "qwen2.5-coder:7b",
          optional = {
            max_tokens = 32,
          },
        },
      },
    },
    config = function(_, opts)
      require("minuet").setup(opts)
    end,
  },
}
