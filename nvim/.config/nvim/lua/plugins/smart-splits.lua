-- Seamless nvim split <-> tmux/herdr pane navigation/resizing.
-- smart-splits v3 ships no multiplexer support in core:
--   tmux:  backend-tmux; tmux.conf binds C-hjkl / M-HJKL keyed on @pane-is-vim, which it sets.
--   herdr: lua/herdr_smart_splits.lua; herdr's config.toml binds C-hjkl to herdr-smart-nav.
-- tmux comes first: when tmux runs inside a herdr pane it is the inner multiplexer.
local function ss(fn)
  return function() require("smart-splits")[fn]() end
end

return {
  "smart-splits-nvim/smart-splits.nvim",
  lazy = false, -- must load at startup so @pane-is-vim is set before the first keypress
  dependencies = {
    {
      "smart-splits-nvim/backend-tmux",
      main = "smart-splits-backend-tmux",
      opts = { disable_nav_when_zoomed = true },
    },
  },
  opts = {
    mux = { backend = { "smart-splits-backend-tmux", "herdr_smart_splits" } },
    move = { at_edge = "stop" },
  },
  keys = {
    { "<C-h>", ss("move_cursor_left"), desc = "Navigate left (nvim/mux)" },
    { "<C-j>", ss("move_cursor_down"), desc = "Navigate down (nvim/mux)" },
    { "<C-k>", ss("move_cursor_up"), desc = "Navigate up (nvim/mux)" },
    { "<C-l>", ss("move_cursor_right"), desc = "Navigate right (nvim/mux)" },
    -- Alt+Shift: plain <A-j>/<A-k> are LazyVim's move-line maps.
    { "<M-H>", ss("resize_left"), desc = "Resize left (nvim/mux)" },
    { "<M-J>", ss("resize_down"), desc = "Resize down (nvim/mux)" },
    { "<M-K>", ss("resize_up"), desc = "Resize up (nvim/mux)" },
    { "<M-L>", ss("resize_right"), desc = "Resize right (nvim/mux)" },
  },
}
