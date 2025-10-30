return {
  {
    "folke/sidekick.nvim",
    opts = {
      cli = {
        mux = { backend = "tmux", enabled = true },
        win = {
          split = { width = 120 },
        },
      },
    },
    keys = {
      {
        "<leader>aa",
        function()
          require("sidekick.cli").toggle({ name = "claude", focus = true })
        end,
        desc = "Sidekick Toggle CLI",
        mode = { "n", "v" },
      },
    },
  },
}
