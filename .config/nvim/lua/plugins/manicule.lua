return {
  {
    "MattiasMTS/manicule.nvim",
    dev = true,
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "ManiculeAdd", "ManiculeList", "ManiculeSend" },
    keys = {
      { "<leader>ma", "<Plug>(manicule-add)", mode = { "n", "x" }, desc = "Manicule: add comment" },
      { "<leader>ml", "<Plug>(manicule-list)", desc = "Manicule: list comments" },
      { "<leader>ms", "<cmd>ManiculeSend<CR>", desc = "Manicule: send comments" },
      { "<leader>mc", "<cmd>ManiculeSend cmux<CR>", desc = "Manicule: send to cmux agent" },
    },
    opts = {
      sinks = {
        cmux = {
          enabled = true,
          clear_on_success = true,
        },
      },
      ui = {
        opacity = 0,
      },
    },
  },
}
