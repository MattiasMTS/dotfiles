local function gemini_copilot_model()
  local ok, codecompanion = pcall(require, "codecompanion.adapters")
  if not ok then
    return
  end
  return codecompanion.extend("copilot", {
    schema = { model = { default = "gemini-2.5-pro" } },
  })
end

return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-lua/plenary.nvim",
      "ravitemer/codecompanion-history.nvim",
      -- "ravitemer/mcphub.nvim",
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
        diff = { enabled = true },
      },
      strategies = {
        chat = { adapter = gemini_copilot_model() },
        inline = { adapter = gemini_copilot_model() },
      },
      extensions = {
        history = {
          enabled = true,
          opts = {
            keymap = "gh",
            save_chat_keymap = "sc",
            auto_save = true,
            expiration_days = 14,
            picker = "fzf-lua",
          },
        },
        --   mcphub = {
        --     callback = "mcphub.extensions.codecompanion",
        --     opts = {
        --       make_vars = true,
        --       make_slash_commands = true,
        --       show_result_in_chat = true,
        --     },
        --   },
      },
    },
    -- check these https://codecompanion.olimorris.dev/usage/chat-buffer/#keymaps
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
