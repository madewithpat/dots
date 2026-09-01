{
  "pwntester/octo.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "folke/snacks.nvim",
  },
  event = "VeryLazy",
  config = function()
    require("octo").setup({
      -- Use gh CLI; no extra auth needed if `gh auth status` works
      gh = {
        cmd = "gh",
        ssh_alternative = "git",
      },
      -- Default picker: snacks (already configured in snacks.lua)
      picker = "snacks",
      -- Default to PR reviews in diffsplit mode, like VS Code
      default_merge_method = "commit",
      ssh_alternative = "git",
      -- Use native floating windows / diffsplit for review
      ui = {
        -- Use diffsplit for review, similar to VS Code PR experience
        review_diff = "vsplit",
      },
    })
  end,
  keys = {
    {
      "<leader>gp",
      function()
        require("octo").pull_requests()
      end,
      desc = "GitHub: PR list",
    },
    {
      "<leader>gi",
      function()
        require("octo").issues()
      end,
      desc = "GitHub: issues",
    },
    {
      "<leader>gr",
      function()
        require("octo").review()
      end,
      desc = "GitHub: review PR",
    },
  },
}
