return {
  {
    "folke/snacks.nvim",
    enabled = true,
    ---@type snacks.Config
    opts = {
      styles = {
        zen = {
          enter = true,
          fixbuf = false,
          minimal = false,
          width = 120,
          height = 0,
          backdrop = { transparent = true, blend = 40 },
          keys = { q = false },
          zindex = 40,
          wo = {
            winhighlight = "NormalFloat:Normal",
          },
          w = {
            snacks_main = true,
          },
        },
        zoom_indicator = {
          text = "▍ zoom  󰊓  ",
          minimal = true,
          enter = false,
          focusable = false,
          height = 1,
          row = 0,
          col = -1,
          backdrop = false,
        },
      },
      bigfile = { enabled = true, size = 1.5 * 1024 * 1024 },
      image = {
        enabled = true,
        math = { enabled = true },
        doc = { inline = true, float = true },
      },
      lazygit = { enabled = true },
      quickfile = { enabled = true },
      statuscolumn = { enabled = false },
      gh = { enabled = false },
      zen = {
        dim = true,
        toggles = {
          dim = true,
          git_signs = true,
          mini_diff_signs = false,
          diagnostics = true,
        },
        center = true, -- center the window
        show = { statusline = true },
      },
      explorer = {
        enabled = false,
        replace_netrw = false,
        trash = true,
      },
      notifier = {
        enabled = false,
        margin = { top = 2, right = 1, bottom = 1 },
        style = "fancy",
        filter = function(notif)
          local ignores = {
            "^No information available$",
            "^client.supports_method is deprecated",
            "^Error requesting document symbols$",
          }
          return not vim.iter(ignores):any(
            ---@param pat string
            function(pat)
              return string.find(notif.msg, pat) ~= nil
            end
          )
        end,
      },
    },
  },
}
