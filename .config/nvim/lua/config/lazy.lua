-- mapleader
vim.g.mapleader = " "
vim.g.maplocalleader = " "

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  })
end
-- add lazy to runtimepath
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

-- Plugins here is set against the cwd of lua/ folder
require("lazy").setup({
  spec = { { import = "plugins" } },
  dev = { path = vim.fn.expand("$HOME") .. "/src/github.com/projects" },
  install = { missing = false },
  ui = { border = "rounded" },

  checker = { enabled = false }, -- check for updates
  change_detection = { notify = false },
  performance = {
    cache = { enabled = true },
    rtp = {
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
vim.cmd([[colorscheme catppuccin]])
