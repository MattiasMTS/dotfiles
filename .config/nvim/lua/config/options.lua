-- -- Default options that are always set:
-- https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- therefore some of the ones below are commented out

-- trying this out we'll see
-- vim.g.lazyvim_python_lsp = "basedpyright"
vim.g.lazyvim_python_ruff = "ruff"

-- vim.g.autoformat = true -- lazyvim enabled

-- mouse
vim.opt.mouse = "a" -- mouse allowed in all modes

-- Show whitespace (trying this out)
vim.opt.list = true
vim.opt.showbreak = "↪"
vim.opt.listchars = { tab = "→ ", eol = "↲", nbsp = "␣", trail = "•" }

vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

vim.opt.hlsearch = true -- highlight search result, clear C-l
vim.opt.incsearch = true -- look incremental
vim.opt.swapfile = false
vim.opt.showcmd = true

vim.opt.inccommand = "split" -- preview incremental substitute -- lazyvim
vim.opt.splitbelow = true
vim.opt.splitright = true

-- numbers on the left
vim.opt.number = true -- lazyvim enabled
vim.opt.relativenumber = true -- lazyvim enabled
vim.opt.signcolumn = "yes"

vim.opt.errorbells = false -- no error sound
vim.opt.showmode = false -- status bar displayed using lualine -- lazyvim

-- indenting
vim.opt.shiftwidth = 4
vim.opt.tabstop = 4

-- extras
vim.opt.backspace = "start,eol,indent"
vim.opt.path:append({ "**" }) -- finding files, search down into subfolders
vim.opt.completeopt = "menu,menuone,noinsert"

-- Completion.
vim.opt.wildignore:append({ ".DS_Store" })

-- Highlight stuff & cursor
vim.opt.cursorline = true -- highlight current line

vim.opt.scrolloff = 10
vim.opt.smoothscroll = true
vim.opt.isfname:append("@-@")

vim.opt.wrap = true
vim.opt.linebreak = true

vim.opt.colorcolumn = "90"

vim.opt.more = false
vim.opt.foldmethod = "manual"

-- language
vim.opt.spelllang = { "en" }
