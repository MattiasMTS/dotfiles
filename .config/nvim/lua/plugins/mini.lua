return {
  {
    "echasnovski/mini.icons",
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
      },
      filetype = {
        gotmpl = { glyph = "󰟓", hl = "MiniIconsGrey" },
        dotenv = { glyph = "", hl = "MiniIconsYellow" },
      },
    },
  },
  -- better diff (e.g. git, codecompanion, diff buffers, etc)
  {
    "echasnovski/mini.diff",
    version = false,
    event = "VeryLazy",
    config = function()
      local diff = require("mini.diff")
      diff.setup({
        -- Disabled by default
        source = diff.gen_source.none(),
      })
    end,
  },
  -- auto pairs
  {
    "echasnovski/mini.pairs",
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
    "echasnovski/mini.hipatterns",
    version = false,
    event = "BufReadPost",
    opts = function()
      local highlighters = {}
      for _, word in ipairs({ "todo", "note", "hack", "fix", "perf" }) do
        highlighters[word] = {
          pattern = string.format("%%f[%%w]()%s()%%f[%%W]", word:upper()),
          group = string.format("MiniHipatterns%s", word:sub(1, 1):upper() .. word:sub(2)),
        }
      end

      return { highlighters = highlighters }
    end,
  },
}
