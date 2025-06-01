-- trying this out we'll see
vim.g.autoformat = true

-- mouse
vim.opt.mouse = "a" -- mouse allowed in all modes

vim.opt.autowrite = true

-- Show whitespace (trying this out)
vim.opt.list = true
vim.opt.showbreak = "↪"
vim.opt.listchars = {
  tab = "▸ ",
  trail = "·",
  extends = "›",
  precedes = "‹",
  nbsp = "␣",
  eol = "↲",
}

vim.opt.fillchars = {
  foldopen = "",
  foldclose = "",
  fold = " ",
  foldsep = " ",
  diff = "╱",
  eob = " ",
}

vim.scriptencoding = "utf-8"
vim.opt.encoding = "utf-8"
vim.opt.fileencoding = "utf-8"

vim.opt.hlsearch = true -- highlight search result
vim.opt.incsearch = true -- look incremental
vim.opt.swapfile = false
vim.opt.showcmd = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.inccommand = "split"
vim.opt.splitbelow = true
vim.opt.splitright = true

-- numbers on the left
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.signcolumn = "yes"

vim.opt.errorbells = false -- no error sound
vim.opt.showmode = false -- status bar displayed using lualine

-- indenting
vim.opt.tabstop = 2
vim.opt.smartindent = true
vim.opt.expandtab = true -- spaces rather than tbas

-- extras
vim.opt.backspace = "start,eol,indent"
vim.opt.path:append({ "**" }) -- finding files, search down into subfolders
vim.opt.completeopt = "menu,menuone,noinsert" -- no insert until I command so
vim.opt.wildmode = "longest:full,full" -- Command-line completion mode
vim.opt.clipboard = "unnamedplus" -- share clipboard
vim.opt.linebreak = true -- Wrap lines at convenient points

-- Completion.
vim.opt.wildignore:append({ ".DS_Store" })

-- Highlight stuff & cursor
vim.opt.cursorline = true -- highlight current line
vim.opt.termguicolors = true -- True color support

vim.opt.scrolloff = 8
vim.opt.smoothscroll = true
vim.opt.isfname:append("@-@")

vim.opt.wrap = false -- no line wrap
vim.opt.linebreak = true -- wrap lines at convenient points

vim.opt.colorcolumn = "90"

vim.opt.more = false
vim.opt.foldmethod = "manual"

-- language
vim.opt.spelllang = { "en" }
