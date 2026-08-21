return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        sources = {
          explorer = {
            hidden = true,
          },
        },
      },
      -- Inline image rendering — replaces image.nvim (removed alongside
      -- diagram.nvim/Mermaid support). Kitty graphics protocol backend,
      -- Ghostty confirmed supported. doc.inline defaults to true and
      -- already includes markdown in its supported filetypes; only the
      -- top-level `enabled` needs setting explicitly. Requires ImageMagick
      -- (already installed, from the image.nvim setup this replaces).
      image = { enabled = true },
    },
  },
}
