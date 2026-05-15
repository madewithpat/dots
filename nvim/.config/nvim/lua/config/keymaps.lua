-- Keymaps added on top of LazyVim defaults.
local map = vim.keymap.set

-- Quick-save
map("n", "<leader>w", "<cmd>w<cr>", { desc = "Save" })

-- Clear search highlight
map("n", "<Esc>", "<cmd>noh<cr>", { desc = "Clear highlights" })

-- Move lines in visual mode
map("v", "J", ":m '>+1<CR>gv=gv", { desc = "Move line down" })
map("v", "K", ":m '<-2<CR>gv=gv", { desc = "Move line up" })

-- Keep cursor centered when jumping
map("n", "<C-d>", "<C-d>zz")
map("n", "<C-u>", "<C-u>zz")
map("n", "n", "nzzzv")
map("n", "N", "Nzzzv")
