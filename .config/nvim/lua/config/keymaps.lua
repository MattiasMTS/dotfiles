-- persistance
-- vim.keymap.set("n", "<leader>s", "lua require('persistence').load()", { desc = "Load last session", silent = true })

-- Vertical movement babey
vim.keymap.set("n", "<C-d>", "<C-d>zz") -- centers screen after jumping down
vim.keymap.set("n", "<C-u>", "<C-u>zz") -- centers screen after jumping up
vim.keymap.set("v", "n", "nzzzv") -- centers screen after jumping down
vim.keymap.set("v", "N", "Nzzzv") -- centers screen after jumping up

-- too lazy to reach ^ on swedish keyboard
vim.keymap.set("n", "<C-p>", "<cmd>e#<CR>", { desc = "Toggle between last open file", silent = true })

-- window management
vim.keymap.set("n", "<C-n>", "<C-w>v") -- split window vertically
vim.keymap.set("n", "<C-s>", "<C-w>s") -- split window horizontally
vim.keymap.set("n", "<C-x>", "<C-w>c") -- close current window

-- quick hackz
vim.keymap.set("v", "J", ":m '>+2<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

vim.keymap.set("n", "<leader>lg", function()
  _G.Snacks.terminal({ "lazygit" }, { esc_esc = false, ctrl_hjkl = false })
end, { desc = "Lazygit current file history" })

-- remap lazy open
vim.keymap.del({ "n" }, "<leader>l")
vim.keymap.set("n", "<leader>ll", "<cmd>Lazy<CR>", { desc = "Open Lazy" })

-- remove bufferline tab switching
vim.keymap.del({ "n" }, "<S-h>")
vim.keymap.del({ "n" }, "<S-l>")
