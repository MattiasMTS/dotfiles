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

vim.api.nvim_create_autocmd("VimEnter", {
  desc = "Auto select virtualenv Nvim open",
  pattern = "*",
  callback = function()
    local venv = vim.fn.findfile("pyproject.toml", vim.fn.getcwd() .. ";")
    if venv ~= "" then
      require("venv-selector").retrieve_from_cache()
    end
  end,
  once = true,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  desc = "Enable csv viewer when opening csv fiels",
  pattern = "*.csv",
  command = "CsvViewEnable",
})
