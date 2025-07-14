return {
  -- https://github.com/Davidyz/VectorCode/blob/main/docs/neovim.md
  {
    "Davidyz/VectorCode", -- Index and search code in your repositories
    cmd = "VectorCode", -- if you're lazy-loading VectorCode
    enabled = false,
    version = "*",
    -- build = "pipx upgrade vectorcode",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
}
