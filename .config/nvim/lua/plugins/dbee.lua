return {
  {
    "jsborjesson/vim-uppercase-sql",
    enabled = false,
    ft = { "sql", "psql", "mysql" },
  },
  {
    "kndndrj/nvim-dbee",
    enabled = true,
    dev = true,
    cmd = "Dbee",
    build = function()
      local binary = vim.fn.expand("$HOME") .. "/.local/share/nvim/dbee/bin/dbee"
      if vim.fn.filereadable(binary) ~= 0 then
        require("dbee").install("go")
      end
    end,
    config = function(_, opts)
      local dbee = require("dbee")
      dbee.setup({
        -- connections
        sources = {
          require("dbee.sources").FileSource:new(vim.fn.expand("$HOME") .. "/.local/share/db_ui/connections.json"),
        },
        -- editor
        -- editor = {},
        -- result
        result = {
          -- number of rows in the results set to display per page
          page_size = 50,
          focus_result = false,
        },
        -- mappings
        mappings = {
          -- next/previous page
          { key = "L", mode = "", action = "page_next" },
          { key = "H", mode = "", action = "page_prev" },
          { key = "]", mode = "", action = "page_last" },
          { key = "[", mode = "", action = "page_first" },
          -- yank rows as csv/json
          { key = "<leader>yj", mode = "n", action = "yank_current_json" },
          { key = "<leader>yj", mode = "v", action = "yank_selection_json" },
          { key = "<leader>YJ", mode = "", action = "yank_all_json" },
          { key = "<leader>yc", mode = "n", action = "yank_current_csv" },
          { key = "<leader>yc", mode = "v", action = "yank_selection_csv" },
          { key = "<leader>YC", mode = "", action = "yank_all_csv" },

          -- cancel current call execution
          { key = "<C-c>", mode = "", action = "cancel_call" },
        },
      })
    end,
    keys = {
      {
        "<leader>bt",
        ":lua require('dbee').toggle()<CR>",
        desc = "toggle db_ui",
        mode = "n",
        silent = true,
      },
      {
        "<leader>bb",
        function()
          require("utils.dadbod").get_dadbod_connections()
        end,
        desc = "set credentials and toggle db_ui",
        mode = "n",
        silent = true,
      },
    },
  },
}
