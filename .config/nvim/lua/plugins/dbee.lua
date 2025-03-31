return {
  {
    "jsborjesson/vim-uppercase-sql",
    enabled = false,
    ft = { "sql", "psql", "mysql" },
  },
  {
    "kndndrj/nvim-dbee",
    dev = true,
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
        editor = {
          -- mappings = {
          --   { key = "<C-m>", mode = "v", action = "run_selection" },
          --   { key = "<C-m>", mode = "n", action = "run_file" },
          --   { key = "<C-r>", mode = "n", action = "refresh" },
          --   { key = "<CR>", mode = "n", action = "run_under_cursor" },
          --   {
          --     key = "<CR>",
          --     mode = "n",
          --     action = function()
          --       local bufnr = vim.api.nvim_get_current_buf()
          --       local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
          --       local cursor = vim.api.nvim_win_get_cursor(0)
          --       local cursor_row = cursor[1] - 1
          --
          --       -- backward propagation for statement (i.e. newline or semicolon)
          --       local start_row, end_row = cursor_row, cursor_row
          --       for i = cursor_row, 0, -1 do
          --         local line = lines[i + 1]
          --         local is_boundary = line == "" or (i < cursor_row and line:match(";%s*$"))
          --         if is_boundary then
          --           start_row = i + 1
          --           break
          --         end
          --         -- top of the file (edge case)
          --         if i == 0 then
          --           start_row = 0
          --         end
          --       end
          --
          --       -- forward propagation for statement (i.e. newline or semicolon)
          --       for i = cursor_row, #lines - 1 do
          --         local line = lines[i + 1]
          --         local is_boundary = (line:match(";%s*$") or line == "") and i >= cursor_row
          --
          --         if is_boundary then
          --           end_row = i
          --           if line == "" then
          --             end_row = i - 1
          --           end
          --           break
          --         elseif i == #lines - 1 then
          --           -- end of the file (edge case)
          --           end_row = i
          --         end
          --       end
          --
          --       local query_lines = {}
          --       for i = start_row, end_row do
          --         table.insert(query_lines, lines[i + 1])
          --       end
          --
          --       local query = table.concat(query_lines, "\n")
          --       if query and query ~= "" then
          --         -- highlight the query
          --         local ns_id = vim.api.nvim_create_namespace("dbee_query_highlight")
          --         vim.api.nvim_set_hl(0, "DBeeRunUnderCursor", { sp = "#b5bd68", undercurl = true })
          --         vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
          --         vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, 0, {
          --           end_row = end_row + 1,
          --           end_col = 0,
          --           hl_group = "DBeeRunUnderCursor",
          --           priority = 100,
          --         })
          --
          --         -- run the query
          --         dbee.execute(query)
          --
          --         -- fade out the highlight
          --         vim.defer_fn(function()
          --           vim.api.nvim_buf_clear_namespace(bufnr, ns_id, 0, -1)
          --         end, 750)
          --       end
          --     end,
          --   },
          -- },
        },
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
