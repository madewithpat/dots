return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      opts.diagnostics = opts.diagnostics or {}
      -- Keep diagnostics available through signs, underlines, floats, and
      -- picker lists, but do not render their messages inline in any buffer.
      opts.diagnostics.virtual_text = false
    end,
  },
}
