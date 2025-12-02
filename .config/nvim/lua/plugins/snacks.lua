return {
  {
    "folke/snacks.nvim",
    enabled = true,
    opts = {
      bigfile = { enabled = true, size = 1.5 * 1024 * 1024 },
      image = { enabled = true },
      lazygit = { enabled = true },
      quickfile = { enabled = true },
      gh = { enabled = true },
      picker = {
        actions = {
          sidekick_send = function(...)
            return require("sidekick.cli.picker.snacks").send(...)
          end,
        },
        win = {
          input = {
            keys = {
              ["<a-a>"] = {
                "sidekick_send",
                mode = { "n", "i" },
              },
            },
          },
        },
      },
    },
  },
}
