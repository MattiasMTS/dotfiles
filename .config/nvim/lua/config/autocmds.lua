vim.api.nvim_create_autocmd({ "InsertLeave" }, {
  desc = "Disable paste mode when leaving insert mode",
  pattern = "*",
  command = "set nopaste",
})

vim.api.nvim_create_autocmd("BufEnter", {
  desc = "Disable trailing newline comment",
  callback = function()
    vim.opt.formatoptions:remove({ "c", "r", "o" })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Enable csv viewer when opening csv fiels",
  pattern = "*.csv",
  command = "CsvViewEnable",
})

vim.api.nvim_create_autocmd("FileType", {
  group = vim.api.nvim_create_augroup("close_with_q", { clear = true }),
  desc = "Close filetypes by pressing <q>",
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

-- vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
--   desc = "Enable cursorline in active window",
--   callback = function()
--     if vim.w.auto_cursorline then
--       vim.wo.cursorline = true
--       vim.w.auto_cursorline = nil
--     end
--   end,
-- })
-- vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
--   desc = "Disable cursorline in inactive window",
--   callback = function()
--     if vim.wo.cursorline then
--       vim.w.auto_cursorline = true
--       vim.wo.cursorline = false
--     end
--   end,
-- })

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
    vim.hl.on_yank({ higroup = "IncSearch" })
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.ghostty",
  callback = function()
    vim.bo.filetype = "ghostty"
  end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("go_template_filetype", { clear = true }),
  pattern = "*.gotmpl,*.tmpl,*.tpl",
  callback = function()
    vim.bo.filetype = "gotmpl"
  end,
})

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
  group = vim.api.nvim_create_augroup("helmfile_filetype", { clear = true }),
  pattern = {
    "*/templates/*.tpl",
    "*/templates/*.yaml",
    "*/templates/*.yml",
    "helmfile*.yaml",
    "helmfile*.yml",
  },
  callback = function()
    vim.bo.filetype = "helm"
  end,
})

vim.api.nvim_create_autocmd("ExitPre", {
  group = vim.api.nvim_create_augroup("octo_exit_pre", { clear = true }),
  callback = function(ev)
    local keep = { "octo" }
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.tbl_contains(keep, vim.bo[buf].filetype) then
        vim.bo[buf].buftype = "" -- set buftype to empty to keep the window
      end
    end
  end,
})
