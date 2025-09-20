return {
  "ibhagwan/fzf-lua",
  dependencies = { "nvim-mini/mini.icons" },
  cmd = "FzfLua",
  keys = {
    -- misc
    { "<leader>fr", "<cmd>FzfLua resume<cr>", desc = "Resume last command" },
    { "<leader>fb", "<cmd>FzfLua buffers sort_mru=true sort_lastused=true<cr>", desc = "Buffers" },
    -- find
    { "<leader>fc", "<cmd>FzfLua highlights<cr>", desc = "Highlights" },
    { "<leader>fd", "<cmd>FzfLua lsp_document_diagnostics<cr>", desc = "Document diagnostics" },
    { "<leader>fD", "<cmd>FzfLua lsp_workspace_diagnostics<cr>", desc = "Workspace diagnostics" },
    { "<leader>ff", "<cmd>FzfLua files<cr>", desc = "Find files" },
    { "<leader>fg", "<cmd>FzfLua git_files<cr>", desc = "Find Files (git-files)" },

    -- search
    { "<leader>sg", "<cmd>FzfLua live_grep<cr>", desc = "Grep" },
    { "<leader>sh", "<cmd>FzfLua help_tags<cr>", desc = "Help" },
    { "<leader>sa", "<cmd>FzfLua autocmds<cr>", desc = "Auto Commands" },
    { "<leader>sk", "<cmd>FzfLua keymaps<cr>", desc = "Key Maps" },
    { "<leader>sM", "<cmd>FzfLua man_pages<cr>", desc = "Man Pages" },
    {
      "<leader>/",
      function()
        require("fzf-lua").lgrep_curbuf({
          winopts = {
            height = 0.7,
            width = 0.7,
            preview = { vertical = "up:70%" },
          },
        })
      end,
      desc = "Grep current buffer",
    },

    -- spelling
    { "z=", "<cmd>FzfLua spell_suggest<cr>", desc = "Spelling suggestions" },
  },
  opts = function()
    local actions = require("fzf-lua.actions")
    return {
      helptags = {
        -- prefer vertical splits
        actions = { ["enter"] = actions.help_vert },
      },
      winopts = { preview = { hidden = true } },
    }
  end,
}
