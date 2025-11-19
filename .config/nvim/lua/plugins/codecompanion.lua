return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
      "ravitemer/codecompanion-history.nvim",
      "franco-ruggeri/codecompanion-spinner.nvim",
    },
    cmd = { "CodeCompanionChat", "CodeCompanionActions", "CodeCompanionCmd", "CodeCompanionHistory" },
    enabled = false,
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
          fold_context = true,
          child_window = { opts = { wrap = true } },
        },
        action_palette = { provider = "fzf_lua" },
        diff = { provider = "mini_diff" },
      },
      memory = {
        opts = {
          chat = { enabled = true },
        },
      },
      strategies = {
        chat = { adapter = { name = "copilot", model = "gpt-4.1" } },
        inline = { adapter = { name = "copilot", model = "gpt-4.1" } },
      },
      extensions = {
        history = {
          enabled = true,
          opts = {
            keymap = "gh",
            save_chat_keymap = "sc",
            auto_save = true,
            auto_generate_title = true,
            continue_last_chat = false,
            delete_on_clearing_chat = true,
            expiration_days = 3,
            picker = "fzf-lua",
            dir_to_save = vim.fn.stdpath("data") .. "/codecompanion-history",
          },
        },
        -- mcphub = {
        --   callback = "mcphub.extensions.codecompanion",
        --   opts = {
        --     make_vars = true, -- Show mcp tool results in chat
        --     make_slash_commands = true, -- Convert resources to #variables
        --     show_result_in_chat = true, -- Add prompts as /slash commands
        --   },
        -- },
      },
    },
    -- check these https://codecompanion.olimorris.dev/usage/chat-buffer/#keymaps
    keys = {
    --stylua: ignore start
      {
        "<leader>ca", "<cmd>CodeCompanionActions<cr>", {"n", "v"}, { noremap = true, silent = true },
      },
      {
        "<leader>ct", "<cmd>CodeCompanionChat Toggle<cr>", {"n", "v"}, { noremap = true, silent = true },
      },
      --stylua: ignore end
    },
  },
  {
    "franco-ruggeri/codecompanion-spinner.nvim",
    lazy = true,
    enabled = false,
    opts = {},
  },
}
