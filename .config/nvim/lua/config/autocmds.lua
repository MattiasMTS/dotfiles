-- turn off paste mode when leaving insert mode.
-- nice to have for e.g. json files
vim.api.nvim_create_autocmd({ "InsertLeave" }, {
  pattern = "*",
  command = "set nopaste",
})

-- disable trailing new line comment
vim.api.nvim_create_autocmd("BufEnter", {
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
  desc = "Disable New Line Comment",
})

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Enable csv viewer when opening csv fiels",
  pattern = "*.csv",
  command = "CsvViewEnable",
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("big_file", { clear = true }),
  desc = "Disable features in big files",
  pattern = "bigfile",
  callback = function(args)
    vim.schedule(function()
      vim.bo[args.buf].syntax = vim.filetype.match({ buf = args.buf }) or ""
    end)
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("close_with_q", { clear = true }),
  desc = "Close with <q>",
  pattern = {
    "git",
    "help",
    "man",
    "qf",
    "query",
    "scratch",
  },
  callback = function(args)
    vim.keymap.set("n", "q", "<cmd>quit<cr>", { buffer = args.buf })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = vim.api.nvim_create_augroup("last_location", { clear = true }),
  desc = "Go to the last location when opening a buffer",
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      vim.cmd('normal! g`"zz')
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("yank_highlight", { clear = true }),
  desc = "Highlight on yank",
  callback = function()
    -- Setting a priority higher than the LSP references one.
    vim.hl.on_yank({ higroup = "IncSearch", priority = 250 })
  end,
})
