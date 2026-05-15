-- Options are set before lazy.nvim startup to avoid loading issues.
-- LazyVim's defaults cover most things; add only genuine overrides here.
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

-- Use system clipboard
vim.opt.clipboard = "unnamedplus"

-- Prefer spaces, 2-wide
vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

-- Persistent undo
vim.opt.undofile = true
