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
          auto_submit = true,
          submit_delay_ms = 150,
          clear_on_success = true,
          pre_text = [[
You are receiving review comments:

Rules:
- Delegate subagents for each M-number comment if large enough.
- If a comment is wrong or unclear, explain why before skipping it.
]],
          post_text = [[
When done, reply with a checklist of comment IDs and what changed.
]],
        },
      },
      ui = { opacity = 0 },
    },
  },
}
