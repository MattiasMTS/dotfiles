-- persistance
-- vim.keymap.set("n", "<leader>s", "lua require('persistence').load()", { desc = "Load last session", silent = true })

-- Clear search and stop snippet on escape
vim.keymap.set({ "i", "n", "s" }, "<esc>", function()
  vim.cmd("noh")
  return "<esc>"
end, { expr = true, desc = "Escape and Clear hlsearch" })

-- Vertical movement babey
vim.keymap.set("n", "<C-d>", "<C-d>zz") -- centers screen after jumping down
vim.keymap.set("n", "<C-u>", "<C-u>zz") -- centers screen after jumping up
vim.keymap.set("v", "n", "nzzzv") -- centers screen after jumping down
vim.keymap.set("v", "N", "Nzzzv") -- centers screen after jumping up

-- better indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")

-- Move lines
vim.keymap.set("n", "<A-j>", "<cmd>execute 'move .+' . v:count1<cr>==", { desc = "Move Down" })
vim.keymap.set("n", "<A-k>", "<cmd>execute 'move .-' . (v:count1 + 1)<cr>==", { desc = "Move Up" })
vim.keymap.set("i", "<A-j>", "<esc><cmd>m .+1<cr>==gi", { desc = "Move Down" })
vim.keymap.set("i", "<A-k>", "<esc><cmd>m .-2<cr>==gi", { desc = "Move Up" })
vim.keymap.set("v", "<A-j>", ":<C-u>execute \"'<,'>move '>+\" . v:count1<cr>gv=gv", { desc = "Move Down" })
vim.keymap.set("v", "<A-k>", ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<cr>gv=gv", { desc = "Move Up" })

-- too lazy to reach ^ on swedish keyboard
vim.keymap.set("n", "<C-p>", "<cmd>e#<CR>", { desc = "Toggle between last open file", silent = true })

-- window management
vim.keymap.set("n", "<C-n>", "<C-w>v") -- split window vertically
vim.keymap.set("n", "<C-s>", "<C-w>s") -- split window horizontally
vim.keymap.set("n", "<C-x>", "<C-w>c") -- close current window

-- quick hackz
vim.keymap.set("v", "J", ":m '>+2<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- lazy open
vim.keymap.set("n", "<leader>ll", "<cmd>Lazy<CR>", { desc = "Open Lazy" })

-- stylua: ignore start
vim.keymap.set("n", "<leader>lg", function() _G.Snacks.terminal({ "lazygit" }, { esc_esc = false, ctrl_hjkl = false }) end, { desc = "Lazygit current file history" })
vim.keymap.set("n", "<leader>gg", function() _G.Snacks.lazygit() end, { desc = "Lazygit (cwd)" })
vim.keymap.set("n", "<leader>gf", function() _G.Snacks.picker.git_log_file() end, { desc = "Git Current File History" })
vim.keymap.set("n", "<leader>gl", function() _G.Snacks.picker.git_log() end, { desc = "Git Log (cwd)" })
