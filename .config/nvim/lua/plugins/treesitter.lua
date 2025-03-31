return {
  { "nvim-treesitter/playground", cmd = "TSPlaygroundToggle" },
  -- add dbt syntax highlighting
  -- {
  --   "nvim-treesitter/nvim-treesitter",
  --   cmd = "TSUpdateSync",
  --   opts = function(_, opts)
  --     opts.matchup = vim.list_extend(opts.matchup or {}, {
  --       enable = true,
  --     })
  --
  --     opts.query_linter = vim.list_extend(opts.query_linter or {}, {
  --       enable = true,
  --       use_virtual_text = true,
  --       lint_events = { "BufWrite", "CursorHold" },
  --     })
  --
  --     opts.highlight = {
  --       enable = true,
  --       additional_vim_regex_highlighting = false,
  --     }
  --
  --     -- Add dbt for jinja2
  --     local parsers_configs = require("nvim-treesitter.parsers").get_parser_configs()
  --     parsers_configs.dbt = {
  --       install_info = {
  --         url = "https://github.com/dbt-labs/tree-sitter-jinja2",
  --         files = { "src/parser.c" },
  --         -- files = { "src/tree_sitter/parser.h" },
  --         branch = "main",
  --       },
  --       filetype = "sql", -- Ensure this matches the filetype of your Jinja2 files
  --     }
  --
  --     -- Ensure the parser is installed
  --     require("nvim-treesitter.install").ensure_installed("dbt")
  --   end,
  -- },
  -- ensure language parsers are installed
  {
    "nvim-treesitter/nvim-treesitter",
    cmd = "TSUpdateSync",
    opts = { ensure_installed = { "go", "gomod", "gowork", "gosum" } },
  },
}
