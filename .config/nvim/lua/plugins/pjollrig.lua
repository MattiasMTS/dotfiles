return {
  {
    "MattiasMTS/pjollrig.nvim",
    dev = true,
    -- Keep using the local development checkout under its existing directory name.
    dir = vim.fn.expand("~/src/github.com/projects/manicule.nvim"),
    event = { "BufReadPost", "BufNewFile" },
    cmd = {
      "PjollrigAdd",
      "PjollrigList",
      "PjollrigEdit",
      "PjollrigDelete",
      "PjollrigResolve",
      "PjollrigToggle",
      "PjollrigNext",
      "PjollrigPrev",
      "PjollrigSend",
      "PjollrigDisplay",
      "PjollrigReview",
      "PjollrigReviewNext",
      "PjollrigReviewPrev",
      "PjollrigReviewFinish",
      "PjollrigReviewStop",
      "PjollrigReviewDiffMode",
    },
    keys = {
      { "<leader>ma", "<Plug>(pjollrig-add)", mode = { "n", "x" }, desc = "Pjollrig: add comment" },
      { "<leader>ml", "<Plug>(pjollrig-list)", desc = "Pjollrig: list comments" },
      { "<leader>ms", "<cmd>PjollrigSend<CR>", desc = "Pjollrig: send comments" },
      { "<leader>mr", "<cmd>PjollrigReview main<CR>", desc = "Pjollrig: review against main" },
      { "<leader>mc", "<cmd>PjollrigSend cmux<CR>", desc = "Pjollrig: send to cmux agent" },
      { "<leader>mD", "<cmd>PjollrigReviewDiffMode<CR>", desc = "Pjollrig: toggle unified/split diff" },
    },
    opts = {
      review = { diff_mode = "unified" },
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
