-- Copilot.
return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    opts = {
      model = "claude-3.7-sonnet", -- Default model to use, see ':CopilotChatModels' for available models
    },
  },
  {
    "zbirenbaum/copilot.lua",
    event = "InsertEnter",
    opts = {
      panel = { enabled = false },
      suggestion = {
        auto_trigger = true,
        -- Use alt to interact with Copilot.
        keymap = {
          accept = false,
          accept_word = "<M-w>",
          accept_line = "<M-l>",
          next = "<M-]>",
          prev = "<M-[>",
          dismiss = "/",
        },
      },
      filetypes = { ["*"] = true },
    },
    config = function(_, opts)
      local copilot = require("copilot.suggestion")
      local luasnip = require("luasnip")

      require("copilot").setup(opts)

      ---@param trigger boolean
      local function set_trigger(trigger)
        if not trigger and copilot.is_visible() then
          copilot.dismiss()
        end
        vim.b.copilot_suggestion_auto_trigger = trigger
        vim.b.copilot_suggestion_hidden = not trigger
      end

      vim.api.nvim_create_autocmd("User", {
        desc = "Disable Copilot inside snippets",
        pattern = { "LuasnipInsertNodeEnter", "LuasnipInsertNodeLeave" },
        callback = function()
          set_trigger(not luasnip.expand_or_locally_jumpable())
        end,
      })
    end,
  },
}
