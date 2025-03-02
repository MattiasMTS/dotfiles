return {
  { "folke/which-key.nvim", enabled = false },
  { "echasnovski/mini.nvim", enabled = false },
  { "lukas-reineke/indent-blankline.nvim", enabled = false },
  { "folke/neoconf.nvim", enabled = false },
  { "folke/persistence.nvim", enabled = true },
  { "folke/flash.nvim", enabled = false },
  { "akinsho/bufferline.nvim", enabled = false },
  { "SmiteshP/nvim-navic", enabled = false },
  {
    "Bekaboo/dropbar.nvim",
    event = "BufEnter",
    enabled = true,
  },
  {
    "nvim-lualine/lualine.nvim",
    enabled = true,
    opts = {
      options = {
        component_separators = "",
        section_separators = "",
      },
      sections = {
        lualine_z = { "encoding" },
      },
    },
  },
  {
    "rcarriga/nvim-notify",
    enabled = true,
  },
  {
    "folke/noice.nvim",
    enabled = true,
    opts = {
      views = {
        notify = {
          replace = true,
        },
      },
      presets = {
        lsp_doc_border = true,
      },
      lsp = {
        progress = {
          enabled = true,
          format = "lsp_progress",
          format_done = "lsp_progress_done",
          view = "notify",
        },
      },
    },
  },
  {
    "folke/snacks.nvim",
    enabled = true,
    opts = {
      dashboard = {
        enabled = true,
        preset = {
          header = "NVIM v" .. vim.version().major .. "." .. vim.version().minor .. "." .. vim.version().patch,
        },
        sections = {
          { section = "header" },
          { section = "keys", gap = 1, padding = 1 },
          { section = "startup" },
        },
      },
    },
  },
}
