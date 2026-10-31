-- Renamed from image.lua — was image.nvim + diagram.nvim + render-markdown.nvim,
-- now just render-markdown.nvim. Inline images moved to Snacks.image
-- (lua/plugins/snacks.lua, already installed/core to LazyVim); Mermaid
-- rendering (diagram.nvim, which required image.nvim as a hard dependency)
-- was dropped entirely — not currently used in any notes.

-- lang.markdown extra strips checkbox rendering and heading icons/sign by
-- default (opts = { checkbox = { enabled = false }, heading = { sign = false,
-- icons = {} } }). Restore both to render-markdown.nvim's own vanilla
-- defaults.
return {
  "MeanderingProgrammer/render-markdown.nvim",
  -- Octo PR/issue buffers are GitHub markdown (lua/plugins/octo.lua).
  ft = { "octo" },
  opts = {
    file_types = { "markdown", "octo" },
    checkbox = {
      enabled = true,
      -- render-markdown only knows the 2 CommonMark states (unchecked/
      -- checked) natively; obsidian.nvim's 3 extra states (~/!/>) need to
      -- be taught here or they render as plain unstyled text. `!`/`>`
      -- icons are placeholders — un-renderable through any text channel
      -- available this session, injected as raw bytes afterward.
      custom = {
        tilde = { raw = "[~]", rendered = "󰰱 ", highlight = "DiagnosticWarn" },
        important = { raw = "[!]", rendered = " ", highlight = "DiagnosticError" },
        forwarded = { raw = "[>]", rendered = " ", highlight = "DiagnosticInfo" },
      },
    },
    heading = {
      sign = true,
      icons = { '󰲡 ', '󰲣 ', '󰲥 ', '󰲧 ', '󰲩 ', '󰲫 ' },
      border = true, -- experiment: rule line above/below instead of relying on the bg band
    },
    -- plugin default is right_pad = 0, which puts text flush against the
    -- bullet glyph; add a space of breathing room.
    bullet = { right_pad = 1 },
    -- GitHub markdown (READMEs, Octo PR/issue bodies) embeds raw HTML.
    -- render-markdown only hides tags listed here, replacing each opening
    -- tag with its icon. <details> can't collapse in a buffer: its content
    -- always shows. Images can't display, so <img> becomes a marker.
    html = {
      tag = {
        details = { icon = "▾ ", highlight = "Special" },
        summary = { icon = "", highlight = "Special", scope_highlight = "Title" },
        picture = { icon = "" },
        source = { icon = "" },
        img = { icon = "[image] ", highlight = "Comment" },
        kbd = { icon = "", scope_highlight = "Special" },
        sub = { icon = "" },
        sup = { icon = "" },
      },
    },
  },
}
