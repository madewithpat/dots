-- Short circuit
if true then
  return {}
end

return {
  "nickjvandyke/opencode.nvim",
  dependencies = {
    "folke/snacks.nvim",
  },
  event = "VeryLazy",
  config = function()
    -- Set global options as recommended by the plugin
    vim.g.opencode_opts = {
      provider = {
        enabled = "snacks",
      },
      events = {
        reload = true, -- Automatically reload buffers when edited by opencode
      },
    }
    -- Ensure autoread is on for buffer reloads
    vim.o.autoread = true
  end,
  keys = {
    {
      "<leader>oa",
      function()
        require("opencode").ask("@this: ", { submit = true })
      end,
      desc = "Ask opencode",
      mode = { "n", "x" },
    },
    {
      "<leader>os",
      function()
        require("opencode").select()
      end,
      desc = "Opencode Select",
      mode = { "n", "x" },
    },
    {
      "<leader>ot",
      function()
        require("opencode").toggle()
      end,
      desc = "Toggle Opencode",
      mode = { "n", "t" },
    },
  },
}
