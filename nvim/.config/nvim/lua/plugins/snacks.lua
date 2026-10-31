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
      image = {
        enabled = true,
        -- Snacks resolves image paths relative to the note, but Obsidian
        -- embeds (![[file.webp]]) name a file that lives anywhere in the
        -- vault — usually under the attachment folder (05_Attachments/...).
        -- For bare filenames in a vault note, look there first (the folder
        -- from .obsidian/app.json, searched recursively), then the whole
        -- vault. Anything else falls back to Snacks' default.
        resolve = function(file, src)
          if src:find("/", 1, true) or src:match("^%a+://") then
            return nil
          end
          local obsidian_dir = vim.fs.find(".obsidian", { path = vim.fs.dirname(file), upward = true, type = "directory" })[1]
          if not obsidian_dir then
            return nil
          end
          local root = vim.fs.dirname(obsidian_dir)
          local search = {}
          local ok, app = pcall(function()
            return vim.json.decode(table.concat(vim.fn.readfile(obsidian_dir .. "/app.json"), "\n"))
          end)
          if ok and type(app) == "table" and type(app.attachmentFolderPath) == "string" then
            search[#search + 1] = root .. "/" .. app.attachmentFolderPath:gsub("^%./", "")
          end
          search[#search + 1] = root
          for _, dir in ipairs(search) do
            local found = vim.fs.find(src, { path = dir, type = "file", limit = 1 })[1]
            if found then
              return found
            end
          end
        end,
      },
    },
  },
}
