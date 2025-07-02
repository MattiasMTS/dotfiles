return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
      "ravitemer/codecompanion-history.nvim",
      "ravitemer/mcphub.nvim",
    },
    cmd = { "CodeCompanionChat", "CodeCompanionActions" },
    enabled = true,
    opts = {
      --Refer to: https://github.com/olimorris/codecompanion.nvim/blob/main/lua/codecompanion/config.lua
      display = {
        chat = {
          show_header_separator = true,
          show_references = true,
          show_token_count = true,
          window = { opts = { number = false, signcolumn = "no" } },
          icons = {
            pinned_buffer = " ",
            watched_buffer = "👀 ",
          },
        },
        action_palette = { provider = "fzf_lua" },
        diff = { enabled = true, provider = "mini_diff" },
      },
      strategies = {
        chat = { adapter = { name = "copilot", model = "gemini-2.5-pro" } },
        inline = { adapter = { name = "copilot", model = "gpt-4.5" } },
        roles = { user = "mattiasmts" },
      },
      extensions = {
        history = {
          enabled = true,
          opts = {
            keymap = "gh",
            save_chat_keymap = "sc",
            auto_save = false,
            auto_generate_title = true,
            continue_last_chat = false,
            delete_on_clearing_chat = false,
            expiration_days = 7,
            picker = "fzf-lua",
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
          },
        },
      },
    },
    -- check these https://codecompanion.olimorris.dev/usage/chat-buffer/#keymaps
    keys = {
    --stylua: ignore start
      {
        "<leader>ca", "<cmd>CodeCompanionActions<cr>", {"n", "v"}, noremap = true, silent = true,
      },
      {
        "<leader>cc", "<cmd>CodeCompanionChat Toggle<cr>", {"n", "v"}, noremap = true, silent = true,
      },
      -- {
      --   "<leader>cc", "<cmd>CodeCompanionChat Add<cr>", {"v"}, noremap = true, silent = true,
      -- },
      --stylua: ignore end
    },
  },
}
