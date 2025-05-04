return {
  {
    "Bekaboo/dropbar.nvim",
    event = "BufEnter",
    enabled = true,
  },
  {
    "nvim-lualine/lualine.nvim",
    enabled = true,
    event = "BufEnter",
    opts = {
      options = {
        component_separators = "",
        section_separators = "",
      },
      sections = {
        lualine_x = { "lsp_status" },
        lualine_z = { "encoding" },
      },
      extensions = { "quickfix", "neo-tree" },
    },
  },
}
