-- Git worktree switching on top of Worktrunk (`wt`). Keymaps live in
-- lua/plugins/worktrunk.lua (<leader>gw) and lua/plugins/octo.lua (PRs).
-- `wt` owns worktree paths and hooks; this only lists, switches, and
-- delegates create/remove/PR checkout to it.

-- Pin the JSON shape here so the user-level `[list] json-schema` can't change it.
local LIST_CMD = { "wt", "list", "--format=json", "--config-set", "list.json-schema = 2" }

local function notify(msg, level)
  vim.notify(msg, level or vim.log.levels.INFO, { title = "Worktrunk" })
end

-- Directory that identifies the repository: the current file's, else cwd.
local function anchor_dir()
  local name = vim.api.nvim_buf_get_name(0)
  if vim.bo.buftype == "" and name ~= "" then
    local dir = vim.fs.dirname(name)
    if vim.uv.fs_stat(dir) then
      return dir
    end
  end
  return vim.uv.cwd()
end

-- Worktrees that exist on this filesystem, plus the forge repo as
-- "owner/name" (nil when wt has no forge remote). Paths recorded on the other
-- side of a devcontainer boundary (host vs /workspace) are dropped.
local function list_worktrees(cwd)
  if vim.fn.executable("wt") == 0 then
    notify("wt is not installed", vim.log.levels.ERROR)
    return nil
  end
  local result = vim.system(LIST_CMD, { cwd = cwd, text = true }):wait()
  if result.code ~= 0 then
    notify(vim.trim(result.stderr ~= "" and result.stderr or result.stdout), vim.log.levels.ERROR)
    return nil
  end
  local ok, decoded = pcall(vim.json.decode, result.stdout, { luanil = { object = true, array = true } })
  if not ok or type(decoded) ~= "table" or type(decoded.items) ~= "table" then
    notify("could not parse `wt list` output", vim.log.levels.ERROR)
    return nil
  end

  local worktrees = {}
  for _, item in ipairs(decoded.items) do
    local wt = item.worktree
    if type(wt) == "table" and wt.path and not wt.prunable and vim.uv.fs_stat(wt.path) then
      local changes = wt.changes or {}
      table.insert(worktrees, {
        branch = item.branch,
        path = vim.fs.normalize(wt.path),
        current = wt.current == true,
        main = wt.main == true,
        previous = wt.previous == true,
        dirty = changes.staged or changes.modified or changes.untracked or changes.renamed
          or changes.deleted or changes.conflicted or false,
      })
    end
  end
  local forge = type(decoded.repo) == "table" and decoded.repo.forge or nil
  local repo = type(forge) == "table" and forge.owner and forge.name and (forge.owner .. "/" .. forge.name) or nil
  return worktrees, repo
end

-- The worktree that owns `path`: the longest worktree path containing it, so
-- files under the main checkout's .worktrees/ belong to that nested worktree.
local function owner(worktrees, path)
  local best
  for _, wt in ipairs(worktrees) do
    if vim.fs.relpath(wt.path, path) and (not best or #wt.path > #best.path) then
      best = wt
    end
  end
  return best
end

-- Wipe unmodified buffers belonging to `wt`; return names of modified ones.
local function wipe_buffers(worktrees, wt)
  local kept = {}
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local name = vim.api.nvim_buf_get_name(buf)
    if vim.api.nvim_buf_is_loaded(buf) and name ~= "" and vim.bo[buf].buftype == "" then
      if owner(worktrees, vim.fs.normalize(name)) == wt then
        if vim.bo[buf].modified then
          table.insert(kept, vim.fn.fnamemodify(name, ":~:."))
        else
          vim.api.nvim_buf_delete(buf, { force = false })
        end
      end
    end
  end
  return kept
end

-- Stop LSP clients rooted in `wt` that no longer have any attached buffer.
local function stop_idle_clients(worktrees, wt)
  for _, client in ipairs(vim.lsp.get_clients()) do
    local root = client.root_dir and vim.fs.normalize(client.root_dir)
    if root and owner(worktrees, root) == wt and vim.tbl_isempty(client.attached_buffers) then
      client:stop()
    end
  end
end

-- `after` runs once the switch completes; without it, switching opens the
-- file picker when the current file has no counterpart in the target.
local function switch_to(worktrees, from, to, after)
  local target_file
  local name = vim.api.nvim_buf_get_name(0)
  if from and vim.bo.buftype == "" and name ~= "" then
    local rel = vim.fs.relpath(from.path, vim.fs.normalize(name))
    if rel then
      local candidate = vim.fs.joinpath(to.path, rel)
      if vim.uv.fs_stat(candidate) then
        target_file = candidate
      end
    end
  end

  vim.cmd.cd(vim.fn.fnameescape(to.path))
  if target_file then
    vim.cmd.edit(vim.fn.fnameescape(target_file))
  end

  if from and from ~= to then
    local kept = wipe_buffers(worktrees, from)
    stop_idle_clients(worktrees, from)
    if #kept > 0 then
      notify("kept modified buffers from " .. (from.branch or from.path) .. ":\n" .. table.concat(kept, "\n"),
        vim.log.levels.WARN)
    end
  end

  notify("switched to " .. (to.branch or to.path))
  if after then
    after(to)
  elseif not target_file then
    Snacks.picker.files()
  end
end

local function format_item(item)
  local wt = item.wt
  local ret = {}
  ret[#ret + 1] = { wt.current and "● " or wt.previous and "◌ " or "  ", "Special" }
  ret[#ret + 1] = { wt.branch or "(detached)", wt.current and "SnacksPickerGitBranchCurrent" or "SnacksPickerGitBranch" }
  if wt.dirty then
    ret[#ret + 1] = { " *", "DiagnosticWarn" }
  end
  if wt.main then
    ret[#ret + 1] = { " main", "Comment" }
  end
  ret[#ret + 1] = { "  " .. vim.fn.fnamemodify(wt.path, ":~"), "SnacksPickerDir" }
  return ret
end

local function pick(title, worktrees, filter, on_choose)
  local items = {}
  for _, wt in ipairs(worktrees) do
    if filter(wt) then
      table.insert(items, { text = (wt.branch or "") .. " " .. wt.path, wt = wt })
    end
  end
  if #items == 0 then
    notify("no worktrees to choose from", vim.log.levels.WARN)
    return
  end
  Snacks.picker({
    title = title,
    items = items,
    format = format_item,
    layout = { preset = "select" },
    confirm = function(picker, item)
      picker:close()
      if item then
        on_choose(item.wt)
      end
    end,
  })
end

local M = {}

function M.switch()
  local worktrees = list_worktrees(anchor_dir())
  if not worktrees then
    return
  end
  local from = owner(worktrees, vim.fs.normalize(anchor_dir()))
  pick("Switch worktree", worktrees, function(wt)
    return wt ~= from
  end, function(to)
    switch_to(worktrees, from, to)
  end)
end

function M.create()
  local cwd = anchor_dir()
  vim.ui.input({ prompt = "New branch: " }, function(branch)
    branch = branch and vim.trim(branch)
    if not branch or branch == "" then
      return
    end
    notify("creating " .. branch .. " (running wt hooks)…")
    -- No --yes: hooks needing approval fail here instead of running silently.
    vim.system({ "wt", "switch", "--create", branch, "--no-cd" }, { cwd = cwd, text = true }, function(result)
      vim.schedule(function()
        if result.code ~= 0 then
          notify(vim.trim(result.stderr ~= "" and result.stderr or result.stdout), vim.log.levels.ERROR)
          return
        end
        local worktrees = list_worktrees(cwd)
        if not worktrees then
          return
        end
        for _, wt in ipairs(worktrees) do
          if wt.branch == branch then
            switch_to(worktrees, owner(worktrees, vim.fs.normalize(anchor_dir())), wt)
            return
          end
        end
        notify("created " .. branch .. ", but its worktree is not on this filesystem", vim.log.levels.WARN)
      end)
    end)
  end)
end

function M.remove()
  local cwd = anchor_dir()
  local worktrees = list_worktrees(cwd)
  if not worktrees then
    return
  end
  local current = owner(worktrees, vim.fs.normalize(cwd))
  pick("Remove worktree", worktrees, function(wt)
    return not wt.main and wt ~= current and wt.branch ~= nil
  end, function(wt)
    vim.ui.select({ "No", "Yes" }, { prompt = "Remove worktree " .. wt.branch .. "?" }, function(choice)
      if choice ~= "Yes" then
        return
      end
      local kept = wipe_buffers(worktrees, wt)
      if #kept > 0 then
        notify("save or discard these buffers first:\n" .. table.concat(kept, "\n"), vim.log.levels.ERROR)
        return
      end
      stop_idle_clients(worktrees, wt)
      vim.system({ "wt", "remove", wt.branch }, { cwd = cwd, text = true }, function(result)
        vim.schedule(function()
          local output = vim.trim(result.stderr ~= "" and result.stderr or result.stdout)
          if result.code ~= 0 then
            notify(output, vim.log.levels.ERROR)
          else
            notify(output ~= "" and output or ("removed " .. wt.branch))
          end
        end)
      end)
    end)
  end)
end

-- Check out GitHub PR `number` as a worktree via `wt switch pr:N` (which runs
-- Worktrunk hooks), switch Neovim into it, then call `after(worktree)`.
-- `repo` ("owner/name"), when given, must match the current checkout's forge
-- repo, so a PR number from one repo never checks out a branch of another.
function M.checkout_pr(number, repo, after)
  local cwd = anchor_dir()
  local worktrees, cwd_repo = list_worktrees(cwd)
  if not worktrees then
    return
  end
  if repo and cwd_repo and repo:lower() ~= cwd_repo:lower() then
    notify(("PR #%d belongs to %s, but this checkout is %s"):format(number, repo, cwd_repo), vim.log.levels.ERROR)
    return
  end
  local from = owner(worktrees, vim.fs.normalize(cwd))

  notify(("checking out PR #%d as a worktree (running wt hooks)…"):format(number))
  -- No --yes: hooks needing approval fail here instead of running silently.
  local cmd = { "wt", "switch", "pr:" .. number, "--no-cd", "--format", "json" }
  vim.system(cmd, { cwd = cwd, text = true }, function(result)
    vim.schedule(function()
      if result.code ~= 0 then
        notify(vim.trim(result.stderr ~= "" and result.stderr or result.stdout), vim.log.levels.ERROR)
        return
      end
      local ok, switched = pcall(vim.json.decode, result.stdout)
      if not ok or type(switched) ~= "table" or type(switched.path) ~= "string" then
        notify("could not parse `wt switch` output", vim.log.levels.ERROR)
        return
      end
      local updated = list_worktrees(cwd)
      if not updated then
        return
      end
      local path = vim.fs.normalize(switched.path)
      for _, wt in ipairs(updated) do
        if wt.path == path then
          -- `from` came from the earlier listing; re-resolve it in this one.
          switch_to(updated, from and owner(updated, from.path), wt, after)
          return
        end
      end
      notify(("PR #%d is checked out at %s, which is not on this filesystem"):format(number, path),
        vim.log.levels.WARN)
    end)
  end)
end

return M
