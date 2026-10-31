-- smart-splits.nvim v3 backend for herdr (protocol 3.0.0).
-- v3 ships no herdr backend; this is the Neovim half of Ctrl+h/j/k/l crossing
-- between Neovim splits and herdr panes. The herdr half is
-- ~/.local/bin/herdr-smart-nav (bin package), bound in herdr's config.toml.
-- Core only calls move()/resize() once Neovim has no window left that way.

local M = {
  name = "herdr",
  protocol_version = "3.0.0",
}

local TIMEOUT_MS = 300

-- Refuse to navigate out of a zoomed pane, matching backend-tmux's
-- disable_nav_when_zoomed. herdr's `pane focus` would move focus behind the
-- zoomed pane otherwise.
M.disable_nav_when_zoomed = true

local function bin()
  local path = vim.env.HERDR_BIN_PATH
  return (path ~= nil and path ~= "") and path or "herdr"
end

local function pane()
  return vim.env.HERDR_PANE_ID
end

---@param args string[]
---@return table|nil result decoded `.result`, nil on any failure
local function herdr(args)
  local ok, res = pcall(function()
    return vim.system(vim.list_extend({ bin() }, args), { text = true, timeout = TIMEOUT_MS }):wait()
  end)
  if not ok or res.code ~= 0 or not res.stdout or res.stdout == "" then
    return nil
  end
  local decoded_ok, decoded = pcall(vim.json.decode, res.stdout)
  if not decoded_ok or type(decoded) ~= "table" then
    return nil
  end
  return decoded.result
end

function M.detect()
  return vim.env.HERDR_ENV == "1" and pane() ~= nil and pane() ~= ""
end

local function layout()
  local result = herdr({ "pane", "layout", "--pane", pane() })
  return result and result.layout
end

-- herdr never wraps (`focus` reports reason = "no_neighbor" at an edge), so
-- at_edge = "stop" needs nothing; "wrap"/"split" fall back to core.
function M.move(direction, _opts)
  if M.disable_nav_when_zoomed then
    local current = layout()
    if current == nil or current.zoomed == true then
      return false
    end
  end
  local result = herdr({ "pane", "focus", "--pane", pane(), "--direction", direction })
  return result ~= nil and result.focus ~= nil and result.focus.changed == true
end

-- `pane resize --amount` is a split-ratio delta, not cells; convert using the
-- tab's pane area (exact for a single split, approximate for nested ones).
function M.resize(direction, opts)
  local cells = (opts and opts.amount) or 3
  local current = layout()
  local area = current and current.area
  if area == nil then
    return false
  end
  local span = (direction == "left" or direction == "right") and area.width or area.height
  if not span or span <= 0 then
    return false
  end
  local result = herdr({
    "pane",
    "resize",
    "--pane",
    pane(),
    "--direction",
    direction,
    "--amount",
    string.format("%.4f", cells / span),
  })
  return result ~= nil and result.resize ~= nil and result.resize.changed == true
end

function M.health()
  if not M.detect() then
    vim.health.info("not inside a herdr pane ($HERDR_ENV / $HERDR_PANE_ID unset)")
    return
  end
  vim.health.ok("herdr pane: " .. pane())
  if vim.fn.executable(bin()) == 1 then
    vim.health.ok("herdr CLI: " .. bin())
  else
    vim.health.error("herdr CLI not executable: " .. bin())
  end
end

return M
