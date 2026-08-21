return {
  "alexghergh/nvim-tmux-navigation",
  config = function()
    require("nvim-tmux-navigation").setup({ disable_when_zoomed = true })
  end,
  keys = {
    { "<C-h>", "<Cmd>NvimTmuxNavigateLeft<CR>", desc = "Navigate left (nvim/tmux)" },
    { "<C-j>", "<Cmd>NvimTmuxNavigateDown<CR>", desc = "Navigate down (nvim/tmux)" },
    { "<C-k>", "<Cmd>NvimTmuxNavigateUp<CR>", desc = "Navigate up (nvim/tmux)" },
    { "<C-l>", "<Cmd>NvimTmuxNavigateRight<CR>", desc = "Navigate right (nvim/tmux)" },
  },
}
