return {
  {
    "stevearc/oil.nvim",
    enabled = true,
    dependencies = { "nvim-tree/nvim-web-devicons" },
    lazy = false,
    ---@module 'oil'
    ---@type oil.SetupOpts
    config = function(_, opts)
      require("oil").setup(opts)

      -- Follow current file in sidebar
      vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
          -- Skip special buffers (terminal, nofile, prompt, etc.)
          if vim.bo.buftype ~= "" or vim.bo.filetype == "oil" then
            return
          end

          local bufname = vim.api.nvim_buf_get_name(0)
          if bufname == "" then
            return
          end

          local current_win = vim.api.nvim_get_current_win()
          local dir = vim.fn.fnamemodify(bufname, ":h")

          -- Defer to ensure buffer is fully loaded
          vim.schedule(function()
            -- Make sure we're still in the same window
            if vim.api.nvim_get_current_win() ~= current_win then
              return
            end

            local oil = require("oil")
            -- Only if there's an oil sidebar open (width <= 45)
            local oil_win = vim.iter(vim.api.nvim_list_wins()):find(function(win)
              local buf = vim.api.nvim_win_get_buf(win)
              return vim.bo[buf].filetype == "oil" and vim.api.nvim_win_get_width(win) <= 45
            end)
            if not oil_win then
              return
            end

            -- Switch to oil window, open dir, switch back
            vim.api.nvim_set_current_win(oil_win)
            oil.open(dir)
            vim.api.nvim_set_current_win(current_win)
          end)
        end,
      })
    end,
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
      {
        "<leader>e",
        function()
          local oil_win = vim.iter(vim.api.nvim_list_wins()):find(function(win)
            return vim.bo[vim.api.nvim_win_get_buf(win)].filetype == "oil"
          end)
          if oil_win then
            vim.api.nvim_win_close(oil_win, true)
            return
          end
          vim.cmd("leftabove vsplit | Oil")
          vim.cmd("vertical resize 40")
          vim.wo.winfixwidth = true
        end,
        desc = "Explorer (Oil toggle)",
      },
    },
  },
  {
    "JezerM/oil-lsp-diagnostics.nvim",
    dependencies = { "stevearc/oil.nvim" },
    ft = "oil",
    opts = {},
  },
  {
    "benomahony/oil-git.nvim",
    dependencies = { "stevearc/oil.nvim" },
    ft = "oil",
    opts = {},
  },
}
