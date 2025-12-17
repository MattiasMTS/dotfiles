return {
  {
    "dmtrKovalenko/fff.nvim",
    opts = {
      debug = {
        enabled = true,
        show_scores = true,
      },
      title = "",
      prompt = "   ",
      layout = {
        height = 0.8,
        width = 0.8,
        prompt_position = "top",
      },
      preview = { enabled = false },
      keymaps = {
        move_up = { "<Up>", "<C-k>" },
        move_down = { "<Down>", "<C-j>" },
      },
    },
    keys = {
      {
        "<leader>ff",
        function()
          require("fff").find_files()
        end,
        desc = "FFFind files",
      },
    },
  },
}
