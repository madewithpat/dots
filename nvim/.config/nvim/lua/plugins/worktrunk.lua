-- Worktree keymaps; the logic is in lua/worktrunk.lua.
return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>gw", group = "worktrees" },
      },
    },
  },
  {
    "folke/snacks.nvim",
    keys = {
      { "<leader>gww", function() require("worktrunk").switch() end, desc = "Switch Worktree" },
      { "<leader>gwc", function() require("worktrunk").create() end, desc = "Create Worktree" },
      { "<leader>gwd", function() require("worktrunk").remove() end, desc = "Remove Worktree" },
    },
  },
}
