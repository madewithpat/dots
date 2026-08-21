return {
  {
    "obsidian-nvim/obsidian.nvim",
    ft = "markdown",
    -- `keys` is also a load trigger for lazy.nvim, independent of `ft` — so
    -- pressing e.g. <leader>oo loads obsidian.nvim and runs the command even
    -- from a non-markdown buffer, instead of requiring a .md file to already
    -- be open first.
    keys = {
      { "<leader>oo", "<cmd>Obsidian today<cr>", desc = "Today's note" },
      { "<leader>oy", "<cmd>Obsidian yesterday<cr>", desc = "Yesterday's note" },
      { "<leader>oT", "<cmd>Obsidian tomorrow<cr>", desc = "Tomorrow's note" },
      { "<leader>od", "<cmd>Obsidian dailies<cr>", desc = "Browse daily notes" },
      { "<leader>on", "<cmd>Obsidian new<cr>", desc = "New note" },
      { "<leader>of", "<cmd>Obsidian quick_switch<cr>", desc = "Find note" },
      { "<leader>os", "<cmd>Obsidian search<cr>", desc = "Search notes" },
      { "<leader>ob", "<cmd>Obsidian backlinks<cr>", desc = "Backlinks" },
      { "<leader>ot", "<cmd>Obsidian tags<cr>", desc = "Search tags" },
      { "<leader>op", "<cmd>Obsidian paste_img<cr>", desc = "Paste image" },
      { "<leader>or", "<cmd>Obsidian rename<cr>", desc = "Rename note" },
      { "<leader>oi", "<cmd>Obsidian template<cr>", desc = "Insert template" },
      { "<leader>ou", "<cmd>Obsidian unique_note<cr>", desc = "Unique note (inbox)" },
      -- Binary bullet<->checkbox toggle. Uses the semi-internal
      -- `_toggle_checkbox` (not the public `toggle_checkbox`) with a custom
      -- 2-state list {"", " "} — "" means "no checkbox", so this collapses
      -- ANY checkbox state back to a plain bullet, or adds `[ ]` to a plain
      -- bullet. Not officially public API; simple enough to be low-risk.
      {
        "<leader>ox",
        function() require("obsidian.actions")._toggle_checkbox({ "", " " }) end,
        desc = "Toggle bullet/checkbox",
        mode = "n",
      },
      {
        "<leader>ox",
        function()
          local actions = require("obsidian.actions")
          for line_nb = vim.fn.line("'<"), vim.fn.line("'>") do
            actions._toggle_checkbox({ "", " " }, line_nb)
          end
        end,
        desc = "Toggle bullet/checkbox (selection)",
        mode = "v",
      },
      -- Direct state-setters via the public `set_checkbox` — jumps straight
      -- to the named state rather than cycling.
      { "<leader>oct", function() require("obsidian.actions").set_checkbox(" ") end, desc = "Checkbox: todo" },
      { "<leader>occ", function() require("obsidian.actions").set_checkbox("x") end, desc = "Checkbox: checked" },
      { "<leader>oci", function() require("obsidian.actions").set_checkbox("~") end, desc = "Checkbox: in progress" },
      { "<leader>ocu", function() require("obsidian.actions").set_checkbox("!") end, desc = "Checkbox: important" },
      { "<leader>ocf", function() require("obsidian.actions").set_checkbox(">") end, desc = "Checkbox: forwarded" },
    },
    opts = {
      workspaces = {
        { name = "second-brain", path = "/Users/patrick/src/second-brain" },
      },
      -- fzf-lua isn't actually installed here — checked, it's absent from
      -- ~/.local/share/nvim/lazy entirely. LazyVim's real default picker is
      -- "auto" (unset in this config), which resolves to snacks.nvim since
      -- that's always present and fzf-lua/telescope require an explicit
      -- extra neither of which is enabled. snacks.nvim is confirmed
      -- installed and already has picker settings configured in
      -- lua/plugins/snacks.lua. (ovim is unaffected — fzf-lua is a real,
      -- deliberately-installed plugin there.)
      picker = { name = "snacks" },
      legacy_commands = false,
      -- obsidian.nvim's own UI renderer (checkboxes/bullets, on by default)
      -- conflicts with render-markdown.nvim — both try to conceal the same
      -- raw checkbox syntax, and render-markdown miscalculates the concealed
      -- width as a result, eating a few characters of the following text.
      -- Confirmed via render-markdown.nvim issue #545. Disabling in favor of
      -- render-markdown.nvim, which we've already tuned for this vault.
      ui = { enable = false },
      daily_notes = {
        folder = "07_Journal/daily",
        template = "daily-note.md",
        -- date_format default ("YYYY-MM-DD") already matches the vault's
        -- filename convention, so it's not overridden here.
      },
      templates = {
        folder = "06_Metadata/Templates",
        -- {{date}} is already a built-in substitution (os.time(), formatted
        -- via templates.date_format, also "YYYY-MM-DD" by default) — no
        -- custom substitutions needed for this template.
      },
      unique_note = {
        folder = "00_Inbox",
        -- `format` as a function bypasses the default ID-generation logic
        -- entirely (including its collision check against existing files —
        -- low risk here since the human-typed slug plus minute-precision
        -- timestamp make a collision unlikely, but not impossible if you
        -- create two unique notes with the same title in the same minute).
        -- Prompts for a title and slugifies it onto the timestamp, matching
        -- the vault's real TIMESTAMP-slug.md convention (stock Obsidian's
        -- own Unique Note plugin does NOT prompt for a title either — this
        -- goes beyond parity on purpose).
        format = function()
          local timestamp = os.date("%Y%m%d%H%M")
          local title = vim.fn.input("Note title: ")
          if title == "" then
            return timestamp
          end
          local slug = title:lower():gsub("[^%w%s-]", ""):gsub("%s+", "-")
          slug = slug:gsub("^%-+", ""):gsub("%-+$", "")
          return timestamp .. "-" .. slug
        end,
      },
    },
  },
  {
    "folke/which-key.nvim",
    opts = {
      spec = {
        -- Icon confidence: Folder/File/Snippet are reused verbatim from
        -- LazyVim.config.icons.kinds — already confirmed rendering in this
        -- exact install (completion menu). The rest are common nf-md glyphs,
        -- not yet visually verified here — flag any that render as boxes.
        { "<leader>o", group = "obsidian", icon = "󰠮" },
        { "<leader>oo", icon = { icon = "󰃭 ", color = "green" } },
        { "<leader>oy", icon = { icon = "󰃭 ", color = "grey" } },
        { "<leader>oT", icon = { icon = "󰃭 ", color = "orange" } },
        -- referenced live rather than copy-pasted — a prior copy-paste from
        -- a headless `vim.inspect()` print silently lost these two glyphs
        -- and left plain spaces instead
        -- `od` opens a picker (dailies), so reuse the magnify glyph from
        -- `os` (already confirmed rendering) rather than Folder, distinguished by color
        { "<leader>od", icon = { icon = "󰍉 ", color = "cyan" } },
        { "<leader>on", icon = LazyVim.config.icons.kinds.File },
        { "<leader>of", icon = "󰈞 " },
        { "<leader>os", icon = "󰍉 " },
        { "<leader>ob", icon = "󰌹 " },
        { "<leader>ot", icon = "󰓹 " },
        { "<leader>op", icon = "󰆏 " },
        { "<leader>or", icon = "󰑕 " },
        { "<leader>oi", icon = "󱄽 " }, -- reused: LazyVim.config.icons.kinds.Snippet
        { "<leader>ou", icon = { icon = LazyVim.config.icons.kinds.File, color = "purple" } }, -- File, distinguished from plain `on`
        { "<leader>ox", icon = { icon = "󰄱 ", color = "yellow" } }, -- matches the plugin's own unchecked-checkbox glyph (ui.checkboxes[" "].char)
        { "<leader>oc", group = "checkbox state", icon = "󰄵 " },
        { "<leader>oct", icon = "󰄱 " }, -- same glyph as `ox`'s unchecked state
        { "<leader>occ", icon = "󰄲 " },
        { "<leader>oci", icon = { icon = "󰰱 ", color = "yellow" } }, -- reused: same codepoint as render-markdown's tilde state, confirmed rendering
        { "<leader>ocu", icon = { icon = "󰀪 ", color = "red" } },
        { "<leader>ocf", icon = { icon = "󰁔 ", color = "blue" } },
      },
    },
  },
}
