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
  },
}
