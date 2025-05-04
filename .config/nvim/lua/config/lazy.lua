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
  spec = {
    -- LSP specifics
    -- { import = "lazyvim.plugins.extras.lang.go" },
    -- { import = "lazyvim.plugins.extras.lang.python" },
    -- { import = "lazyvim.plugins.extras.lang.typescript" },
    -- { import = "lazyvim.plugins.extras.lang.java" },
    -- { import = "lazyvim.plugins.extras.lang.kotlin" },
    -- { import = "lazyvim.plugins.extras.lang.json" },
    -- { import = "lazyvim.plugins.extras.lang.yaml" },
    -- { import = "lazyvim.plugins.extras.lang.toml" },
    -- { import = "lazyvim.plugins.extras.lang.docker" },
    -- { import = "lazyvim.plugins.extras.lang.helm" },
    -- { import = "lazyvim.plugins.extras.lang.nix" },

    -- DAP specifics
    -- { import = "lazyvim.plugins.extras.dap.core" },

    -- AI stuff
    -- { import = "lazyvim.plugins.extras.ai.copilot-chat" },

    -- editor.lua
    -- { import = "lazyvim.plugins.extras.editor.outline" },
    -- { import = "lazyvim.plugins.extras.ui.treesitter-context" },

    -- load custom plugins
    { import = "plugins" },
  },
  dev = { path = vim.fn.expand("$HOME") .. "/src/github.com/projects" },
  install = { missing = false },
  ui = { border = "rounded" },

  checker = { enabled = false }, -- check for updates
  change_detection = { notify = false },
  performance = {
    rtp = {
      disabled_plugins = {
        "gzip",
        "matchit",
        "matchparen",
        "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

-- cmd post lazy is loaded
vim.cmd([[colorscheme hybrid]])
