return {
  {
    dir = vim.fn.expand("$VIMRUNTIME/pack/dist/opt/nvim.undotree"),
    keys = {
      { "<leader>u", "<Cmd>Undotree<CR>", desc = "Toggle Undotree" },
    },
  },
  {
    dir = vim.fn.expand("$VIMRUNTIME/pack/dist/opt/nvim.difftool"),
    cmd = { "DiffTool" },
  },
}
