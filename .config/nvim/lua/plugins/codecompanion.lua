return {
  {
    "olimorris/codecompanion.nvim",

    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
      -- "saghen/blink.cmp",
      -- "ravitemer/mcphub.nvim",
    },
    enabled = true,
    opts = {
      --Refer to: https://github.com/olimorris/codecompanion.nvim/blob/main/lua/codecompanion/config.lua
      display = {
        chat = {
          show_header_separator = true,
          show_references = true,
          show_token_count = true,
          window = { opts = { number = false, signcolumn = "no" } },
        },
      },
      strategies = {
        chat = {
          adapter = "copilot",
          copilot_model = "claude-3-7-sonnet", --gemini-2.5-pro
        },
        inline = {
          adapter = "copilot",
        },
      },
      -- extensions = {
      --   mcphub = {
      --     callback = "mcphub.extensions.codecompanion",
      --     opts = {
      --       make_vars = true,
      --       make_slash_commands = true,
      --       show_result_in_chat = true,
      --     },
      --   },
      -- },
    },
    keys = {
    --stylua: ignore start
      {
        "<leader>ca", "<cmd>CodeCompanionActions<cr>", {"n", "v"}, noremap = true, silent = true,
      },
      {
        "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", {"n"}, noremap = true, silent = true,
      },
      {
        "<leader>cc", "<cmd>CodeCompanionChat Add<cr>", {"v"}, noremap = true, silent = true,
      },
      --stylua: ignore end
    },
  },
}
