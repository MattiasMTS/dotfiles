return {
  {
    "nvim-mini/mini.files",
    version = false,
    keys = {
      {
        "<leader>e",
        function()
          local mf = require("mini.files")
          if not mf.close() then
            mf.open(vim.api.nvim_buf_get_name(0), true)
          end
        end,
        desc = "Open MiniFiles (current file)",
      },
    },
    config = function(_, opts)
      opts = vim.tbl_deep_extend("force", opts or {}, {
        mappings = {
          go_in_plus = "l",
          synchronize = ":w",
        },
      })
      require("mini.files").setup(opts)
    end,
  },
  {
    "nvim-mini/mini.icons",
    lazy = true,
    version = false,
    event = "VeryLazy",
    init = function()
      package.preload["nvim-web-devicons"] = function()
        require("mini.icons").mock_nvim_web_devicons()
        return package.loaded["nvim-web-devicons"]
      end
    end,
    opts = {
      file = {
        [".go-version"] = { glyph = "", hl = "MiniIconsBlue" },
        [".keep"] = { glyph = "󰊢", hl = "MiniIconsGrey" },
        ["devcontainer.json"] = { glyph = "", hl = "MiniIconsAzure" },
        [".eslintrc.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        [".node-version"] = { glyph = "", hl = "MiniIconsGreen" },
        [".prettierrc"] = { glyph = "", hl = "MiniIconsPurple" },
        [".yarnrc.yml"] = { glyph = "", hl = "MiniIconsBlue" },
        ["eslint.config.js"] = { glyph = "󰱺", hl = "MiniIconsYellow" },
        ["package.json"] = { glyph = "", hl = "MiniIconsGreen" },
        ["tsconfig.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["tsconfig.build.json"] = { glyph = "", hl = "MiniIconsAzure" },
        ["yarn.lock"] = { glyph = "", hl = "MiniIconsBlue" },
      },
      filetype = {
        gotmpl = { glyph = "󰟓", hl = "MiniIconsGrey" },
        dotenv = { glyph = "", hl = "MiniIconsYellow" },
      },
    },
  },
  -- auto pairs
  {
    "nvim-mini/mini.pairs",
    version = false,
    event = "InsertEnter",
    opts = {
      modes = { insert = true, command = true, terminal = false },
      -- skip autopair when next character is one of these
      skip_next = [=[[%w%%%'%[%"%.%`%$]]=],
      -- skip autopair when the cursor is inside these treesitter nodes
      skip_ts = { "string" },
      -- skip autopair when next character is closing pair
      -- and there are more closing pairs than opening pairs
      skip_unbalanced = true,
      -- better deal with markdown code blocks
      markdown = true,
    },
  },
  -- Highlight patterns in text.
  {
    "nvim-mini/mini.hipatterns",
    version = false,
    event = "BufReadPost",
    opts = function()
      local highlighters = {}
      for _, word in ipairs({ "todo", "note", "hack", "fix", "perf", "fixme" }) do
        highlighters[word] = {
          pattern = string.format("%%f[%%w]()%s()%%f[%%W]", word:upper()),
          group = string.format("MiniHipatterns%s", word:sub(1, 1):upper() .. word:sub(2)),
        }
      end

      return { highlighters = highlighters }
    end,
  },
}
