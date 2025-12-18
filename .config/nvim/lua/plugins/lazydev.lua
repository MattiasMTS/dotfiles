return {
  "folke/lazydev.nvim",
  ft = "lua",
  cmd = "LazyDev",
  opts = {
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "oil.nvim", words = { "oil" } },
      { path = "snacks.nvim", words = { "snacks" } },
    },
  },
}
