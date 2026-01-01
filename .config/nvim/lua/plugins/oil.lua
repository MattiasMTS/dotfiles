return {
  {
    "stevearc/oil.nvim",
    enabled = false,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    ---@module 'oil'
    ---@type oil.SetupOpts
    opts = {
      delete_to_trash = true,
      skip_confirm_for_simple_edits = true,
      watch_for_changes = true,
      constrain_cursor = "name",
      view_options = {
        show_hidden = true,
      },
      win_options = {
        winbar = "%#@attribute.builtin#%{substitute(v:lua.require('oil').get_current_dir(), '^' . $HOME, '~', '')}",
      },
      lsp_file_methods = {
        autosave_changes = true,
      },
      -- make it work with smart-splits
      keymaps = {
        ["<C-h>"] = false,
        ["<C-l>"] = false,
        ["<C-j>"] = false,
        ["<C-k>"] = false,
      },
    },
    keys = {
      { "-", "<CMD>Oil<CR>", desc = "Open parent directory" },
    },
  },
  {
    "JezerM/oil-lsp-diagnostics.nvim",
    enabled = false,
    dependencies = { "stevearc/oil.nvim" },
    ft = "oil",
    opts = {},
  },
  {
    "benomahony/oil-git.nvim",
    enabled = false,
    dependencies = { "stevearc/oil.nvim" },
    ft = "oil",
    opts = {},
  },
}
