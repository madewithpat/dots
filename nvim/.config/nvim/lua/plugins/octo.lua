-- GitHub issues/PRs/reviews through the gh CLI (octo.nvim), with PR checkout
-- going through Worktrunk worktrees (lua/worktrunk.lua) instead of switching
-- the current checkout's branch.

-- The PR shown in the current Octo buffer, if any.
local function current_pr()
  local buffer = require("octo.utils").get_current_buffer()
  if buffer and buffer:isPullRequest() then
    return buffer
  end
end

-- Check out the current Octo PR buffer's PR as a worktree, then run `after`.
-- Without `after`, the PR buffer stays in front.
local function pr_to_worktree(after)
  local pr = current_pr()
  if not pr then
    vim.notify("not in an Octo pull request buffer", vim.log.levels.WARN, { title = "Octo" })
    return
  end
  require("worktrunk").checkout_pr(pr.number, pr.repo, after or function() end)
end

-- Review in a worktree: from a PR buffer, check that PR out first; anywhere
-- else, review the PR of the current branch.
local function review()
  if current_pr() then
    pr_to_worktree(function()
      vim.cmd("Octo review")
    end)
  else
    vim.cmd("Octo review")
  end
end

return {
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        { "<leader>go", group = "octo" },
      },
    },
  },
  -- Layered on lazyvim.plugins.extras.util.octo (lazyvim.json), which owns
  -- loading, <leader>gi/gI/gp/gP/gr, Octo-buffer which-key groups, @/#
  -- completion, and the markdown treesitter registration.
  {
    "pwntester/octo.nvim",
    -- nvim-treesitter loads on LazyFile; opening Octo first would otherwise
    -- leave its FileType highlighting hook unregistered (raw markdown).
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      picker = "snacks",
      -- The extra defaults to Projects v2, which needs the `read:project`
      -- token scope; without it, PR buffers fail to load.
      default_to_projects_v2 = false,
      -- Remotes use per-account SSH host aliases (gh-ggt, gh-otter, …).
      ssh_aliases = { ["gh%-[%w_-]+"] = "github.com" },
      -- In a checkout of the PR branch, the review's right side is the real
      -- file, so LSP and edits work during review.
      use_local_fs = true,
      mappings = {
        -- <C-a> is the tmux prefix; keep approve with the other review keys
        -- (<localleader>vs submit, <localleader>vd discard).
        submit_win = {
          approve_review = { lhs = "<localleader>va" },
        },
      },
      picker_config = {
        snacks = {
          actions = {
            pull_requests = {
              {
                name = "check_out_pr",
                lhs = "<C-o>",
                mode = { "n", "i" },
                desc = "checkout PR as worktree",
                fn = function(picker, item)
                  picker:close()
                  require("worktrunk").checkout_pr(item.number, item.repository.nameWithOwner, function()
                    vim.cmd("Octo pr edit " .. item.number)
                  end)
                end,
              },
            },
          },
        },
      },
    },
    keys = {
      -- The extra's <leader>gS (Octo search) shadows LazyVim's git stash
      -- picker; Octo search lives on <leader>gos instead.
      { "<leader>gS", false },
      { "<leader>gor", review, desc = "Review PR (in worktree)" },
      { "<leader>gon", "<cmd>Octo notification list<cr>", desc = "Notifications" },
      { "<leader>gos", "<cmd>Octo search<cr>", desc = "Search GitHub" },
      { "<localleader>pw", function() pr_to_worktree() end, ft = "octo", desc = "Checkout PR as worktree" },
      { "<localleader>vw", review, ft = "octo", desc = "Review PR in worktree" },
    },
  },
}
