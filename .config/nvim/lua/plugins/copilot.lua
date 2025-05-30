return {
  {
    "CopilotC-Nvim/CopilotChat.nvim",
    enabled = false,
    cmd = "CopilotChat",
    opts = {
      model = "gemini-2.0-flash-001",
    },
  },
  {
    "zbirenbaum/copilot.lua",
    enabled = true,
    dependencies = { "L3MON4D3/LuaSnip" },
    event = "InsertEnter",
    cmd = "Copilot",
    build = ":Copilot auth",
    opts = {
      panel = { enabled = false },
      suggestion = {
        hide_during_completion = false,
        auto_trigger = true,
        debounce = 100, -- Delay in milliseconds before triggering suggestions.
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
      filetypes = {
        yaml = true,
        markdown = true,
      },
      copilot_model = "gemini-2.5-pro",
    },
    -- config = function(_, opts)
    --   local copilot = require("copilot.suggestion")
    --   local luasnip = require("luasnip")
    --
    --   require("copilot").setup(opts)
    --
    --   ---@param trigger boolean
    --   local function set_trigger(trigger)
    --     if not trigger and copilot.is_visible() then
    --       copilot.dismiss()
    --     end
    --     vim.b.copilot_suggestion_auto_trigger = trigger
    --     vim.b.copilot_suggestion_hidden = not trigger
    --   end
    --
    --   vim.api.nvim_create_autocmd("User", {
    --     desc = "Disable Copilot inside snippets",
    --     pattern = { "LuasnipInsertNodeEnter", "LuasnipInsertNodeLeave" },
    --     callback = function()
    --       set_trigger(not luasnip.expand_or_locally_jumpable())
    --     end,
    --   })
    -- end,
  },
}
