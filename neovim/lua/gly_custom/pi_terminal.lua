-- Mirror the tmux-hosted pi in a Neovim split.
--
-- pi runs once, in a tmux pane, in the directory of the project it serves. This
-- split attaches to that pane as a second tmux client instead of starting
-- another pi, so both views are the same process and the same session file: a
-- questionnaire raised by pi can be answered in either view, and nothing goes
-- stale. Prompts are not typed here -- the float sends them over the socket.
--
-- The pane is the one whose `pane_current_path` equals Neovim's `:pwd`, so `:cd`
-- moves the match. Only panes count: a pi started outside tmux has no pane for
-- the split to attach to and is never detected. Only the interactive TUI counts
-- too: a headless pi in a pane (a subagent on `--mode rpc`, or `pi -p`) is
-- ignored, so it is never mirrored and never makes a directory ambiguous. Two
-- TUI pi panes in the directory, or none in it, are reported instead of guessed.
--
-- Clients attached to one session share its current window, so each mirror gets
-- its own session in the target pane's session group. Grouped sessions share the
-- windows but keep an independent current window, which lets the split sit on
-- the pi window while the outer client stays where it is. `-f ignore-size` keeps
-- the mirror from resizing the window that client is using, so the split shows
-- the top-left crop when it is narrower.
--
-- The mirror session is named per pi pane (`pi-mirror-<pane id>`), so two Neovim
-- instances in different directories each get their own mirror instead of sharing
-- one session and showing whichever pi claimed it first.
--
-- The prefix is a server option shared with the outer client, so copy-mode in
-- the split is `C-b C-b [` while Neovim itself runs inside tmux, and a plain
-- `C-b [` when it does not. Typing in the split reaches the same pi.
local M = {}

--- Prefix for mirror sessions; the pane id makes each one unique. Matching the
--- prefix (rather than the full name) also covers a leftover legacy `pi-mirror`.
M.mirror_prefix = "pi-mirror"

--- True when a session name is a mirror session.
--- @param name string
--- @return boolean
local function is_mirror_session(name)
  return name:sub(1, #M.mirror_prefix) == M.mirror_prefix
end

--- Mirror session name for a pi pane.
--- @param pane table
--- @return string
local function mirror_name(pane)
  return M.mirror_prefix .. "-" .. (pane.pane_id:gsub("%%", ""))
end

--- Attach command for a mirror session.
--- @param name string
--- @return string
local function attach_cmd(name)
  return "tmux attach-session -f ignore-size -t " .. name
end

--- Mirror buffers open in this Neovim instance.
local active = {}

--- Run tmux, returning its output and whether it succeeded.
--- @param args string[]
--- @return string output
--- @return boolean ok
local function tmux(args)
  local cmd = { "tmux" }
  vim.list_extend(cmd, args)
  local out = vim.fn.system(cmd)
  return out, vim.v.shell_error == 0
end

--- Absolute, slash-trimmed form of a directory, for comparison.
--- @param path string|nil
--- @return string
local function normalized(path)
  if type(path) ~= "string" or path == "" then
    return ""
  end
  local trimmed = (vim.fn.fnamemodify(path, ":p"):gsub("/+$", ""))
  -- Trimming the root's slash would leave nothing to compare.
  return trimmed == "" and "/" or trimmed
end

--- True when a pane's foreground command is pi.
--- @param command string
--- @return boolean
local function is_pi(command)
  return command == "pi" or command:match("^pi[%.-]") ~= nil
end

--- True when a pane is running the interactive pi TUI rather than a headless
--- run (a subagent). Headless pi is still `pi` in the pane, so it would
--- otherwise look like a valid mirror target.
---
--- `alternate_on` is 1 while a full-screen TUI owns the alternate screen;
--- headless pi (`-p` / `--print`, `--mode rpc` / `json`) never takes it. A
--- `--tui-mode regular` pi does not either, so also accept pi's terminal title,
--- which only the interactive mode sets (`<APP_TITLE> - ...`, `π - ...` by
--- default; a shell in this image leaves tmux's default title alone).
--- @param pane table
--- @return boolean
local function is_tui(pane)
  return pane.alternate_on == "1" or pane.title:match("^π %- ") ~= nil
end

--- Every tmux pane whose foreground command is the interactive pi TUI.
---
--- Mirror sessions are skipped and panes are deduplicated by pane id: a mirror
--- is grouped with its pi session, so tmux lists the same pane again under the
--- mirror's name, which would otherwise read as a second pi in the directory.
--- Headless pi panes (subagents) are dropped by `is_tui`, so they neither get
--- mirrored nor make a directory look ambiguous.
--- @return table[] panes
local function pi_panes()
  local format = table.concat({
    "#{session_name}",
    "#{window_index}",
    "#{window_id}",
    "#{pane_index}",
    "#{pane_id}",
    "#{pane_pid}",
    "#{pane_current_command}",
    "#{alternate_on}",
    "#{pane_title}",
    "#{pane_current_path}",
  }, "\t")
  local out, ok = tmux({ "list-panes", "-a", "-F", format })
  if not ok then
    return {}
  end

  local panes, seen = {}, {}
  for line in vim.gsplit(out, "\n", { plain = true }) do
    local session, window, window_id, pane, pane_id, pid, command, alternate_on, title, path =
      line:match("^(.-)\t(.-)\t(.-)\t(.-)\t(.-)\t(.-)\t(.-)\t(.-)\t(.-)\t(.*)$")
    if session and not is_mirror_session(session) and is_pi(command) and not seen[pane_id] then
      local candidate = {
        session = session,
        window = window,
        window_id = window_id,
        pane = pane,
        pane_id = pane_id,
        pid = pid,
        alternate_on = alternate_on,
        title = title,
        path = path,
        target = session .. ":" .. window .. "." .. pane,
      }
      if is_tui(candidate) then
        seen[pane_id] = true
        panes[#panes + 1] = candidate
      end
    end
  end
  return panes
end

--- One line per pane, for a notification.
--- @param lines string[]
--- @param panes table[]
local function append_panes(lines, panes)
  for _, pane in ipairs(panes) do
    lines[#lines + 1] = string.format("  %s  pid %s  %s", pane.target, pane.pid, pane.path)
  end
end

--- Pick the pi pane for Neovim's working directory.
--- @return table|nil pane
--- @return string|nil reason when nothing was chosen
function M.resolve()
  local cwd = vim.fn.getcwd()
  if type(cwd) ~= "string" or cwd == "" then
    cwd = vim.uv.cwd()
  end
  if type(cwd) ~= "string" or cwd == "" then
    return nil, "Neovim's working directory is unavailable; run :cd <project> and try again."
  end
  cwd = normalized(cwd)

  local here, elsewhere = {}, {}
  for _, pane in ipairs(pi_panes()) do
    if normalized(pane.path) == cwd then
      here[#here + 1] = pane
    else
      elsewhere[#elsewhere + 1] = pane
    end
  end

  if #here == 1 then
    return here[1], nil
  end

  local lines = {}
  if #here > 1 then
    lines[#lines + 1] =
      string.format("%d pi panes in %s; close one and press <leader>kk again:", #here, cwd)
    append_panes(lines, here)
  else
    lines[#lines + 1] = string.format("no pi pane in %s (the mirror only sees pi in tmux).", cwd)
    if #elsewhere > 0 then
      lines[#lines + 1] = "pi in tmux elsewhere:"
      append_panes(lines, elsewhere)
    end
    lines[#lines + 1] = "start pi in tmux here with: tmux new-session -A -s pi 'pi -c'"
  end
  return nil, table.concat(lines, "\n")
end

--- True when this pane's mirror session already shows `pane`.
---
--- Window and pane ids are compared, not indices: every session's first pane is
--- `0.0`, so an index comparison would report a mirror grouped with a different
--- session as already showing this pane.
--- @param pane table
--- @return boolean
local function mirror_shows(pane)
  local out, ok =
    tmux({ "display-message", "-p", "-t", mirror_name(pane), "#{window_id}.#{pane_id}" })
  return ok and vim.trim(out) == pane.window_id .. "." .. pane.pane_id
end

--- Point this pane's mirror session at `pane`, reusing it when it already shows
--- that pane so a second Neovim in the same directory is not detached.
--- @param pane table
--- @return boolean ok
local function prepare_mirror(pane)
  local name = mirror_name(pane)
  if not mirror_shows(pane) then
    tmux({ "kill-session", "-t", name })
    if not tmux({ "new-session", "-d", "-t", pane.session, "-s", name }) then
      return false
    end
  end

  -- A grouped session keeps its own current window, so this moves the mirror
  -- without moving the client that shares the same windows. Selecting the pane
  -- does change the shared window, which only shows when it holds several panes.
  if not tmux({ "select-window", "-t", name .. ":" .. pane.window }) then
    return false
  end
  tmux({ "select-pane", "-t", name .. ":" .. pane.window .. "." .. pane.pane })
  return true
end

--- Remove a mirror session once no open split of this instance still uses it.
--- A closed terminal buffer is still findable, so open splits are tracked here
--- rather than searched for.
--- @param name string|nil
local function cleanup_mirror(name)
  if name == nil then
    return
  end
  for _, used in pairs(active) do
    if used == name then
      return
    end
  end
  tmux({ "kill-session", "-t", name })
end

--- True when a terminal buffer name belongs to the pi mirror.
--- @param name string|nil
--- @return boolean
function M.is_pi_terminal(name)
  if type(name) ~= "string" or name == "" then
    return false
  end
  return name:lower():match(":tmux%s+attach") ~= nil
end

--- Locate the pi mirror buffer, plus its window when it is visible.
--- @return integer|nil buf
--- @return integer|nil win
function M.find()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if
      vim.api.nvim_buf_is_valid(buf)
      and vim.api.nvim_buf_is_loaded(buf)
      and vim.bo[buf].buftype == "terminal"
      and M.is_pi_terminal(vim.api.nvim_buf_get_name(buf))
    then
      local win = vim.fn.bufwinid(buf)
      return buf, (win ~= -1) and win or nil
    end
  end
  return nil, nil
end

--- Open the pi mirror in a right-hand split, hide it, or restore it.
--- Hiding keeps the tmux client attached, so restoring resumes the same view.
function M.toggle()
  local buf, win = M.find()

  if buf and win then
    pcall(vim.api.nvim_win_hide, win)
    return
  end

  local pane, reason = M.resolve()
  if not pane then
    vim.notify(reason, vim.log.levels.WARN)
    return
  end

  -- A buffer showing another pane is stale: closing it drops its mirror client
  -- and its session, and a fresh one is built below.
  if buf and vim.b[buf].pi_mirror_target ~= pane.pane_id then
    vim.api.nvim_buf_delete(buf, { force = true })
    buf = nil
  end

  local name = mirror_name(pane)
  if not prepare_mirror(pane) then
    vim.notify(
      "Could not prepare the tmux session '" .. name .. "' for " .. pane.target .. ".",
      vim.log.levels.ERROR
    )
    return
  end

  if buf then
    vim.cmd("botright vsplit")
    vim.api.nvim_win_set_buf(0, buf)
    vim.cmd("startinsert")
    return
  end

  vim.cmd("botright vsplit")
  vim.cmd("terminal " .. attach_cmd(name))

  local mirror = vim.api.nvim_get_current_buf()
  vim.b[mirror].pi_mirror_target = pane.pane_id
  active[mirror] = name
  vim.api.nvim_create_autocmd("TermClose", {
    buffer = mirror,
    once = true,
    callback = function()
      local session = active[mirror]
      active[mirror] = nil
      cleanup_mirror(session)
    end,
  })
  vim.cmd("startinsert")
end

return M
