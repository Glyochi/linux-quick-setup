-- Context-aware floating prompt for pi.
--
-- The float is a vertical stack in one centered column: a read-only `reference`
-- pane on top showing the `@<relfile>` reference, and the `prompt` pane directly
-- below it. Messages carry references, not content, so pi reads the file from
-- disk; when the buffer is modified the reference pane adds an unsaved-changes
-- notice instead of a transient notification. Every send goes over the plugin's
-- socket path to the pi running in tmux (see `M.deliver`), so a questionnaire pi
-- raises is always raised in that one process.
local M = {}

local CONTEXTS = { "selection", "file" }

--- Compose a reference-only message. Pure: no editor state is read here.
--- @param context "selection"|"file"
--- @param ctx table { prompt, file, start_line, end_line }
--- @return string
function M.compose(context, ctx)
  ctx = ctx or {}
  local prompt = vim.trim(ctx.prompt or "")
  local file = ctx.file or ""
  if file == "" then
    return prompt
  end

  if context == "selection" then
    local ref = string.format("@%s lines %d-%d", file, ctx.start_line or 0, ctx.end_line or 0)
    if prompt == "" then
      return "Look at " .. ref
    end
    return string.format("%s\n\nFrom %s", prompt, ref)
  end

  -- file
  if prompt == "" then
    return "Look at @" .. file
  end
  return string.format("%s\n\nFile: @%s", prompt, file)
end

--- Next context in the cycle. Without a visual selection only `file` applies.
--- Pure.
--- @param current string
--- @param has_selection boolean
--- @return string
function M.next_context(current, has_selection)
  if not has_selection then
    return "file"
  end
  if current == "selection" then
    return "file"
  end
  return "selection"
end

--- Deliver a composed message.
---
--- Always over the pi-nvim socket, to the single pi running in tmux. That keeps
--- the prompt in the process that owns the session, so an `ask_user_question`
--- questionnaire is raised there and stays answerable in the tmux window, while
--- the mirror split shows it as part of the same transcript. Nothing is pasted
--- into a terminal buffer.
--- @param message string
function M.deliver(message)
  local ok, pi = pcall(require, "pi-nvim")
  if not ok then
    vim.notify("pi-nvim is not available", vim.log.levels.ERROR)
    return
  end

  if not pi.get_socket_path() then
    vim.notify(
      "No pi session is reachable. Start pi in tmux: tmux new-session -A -s pi 'pi -c'",
      vim.log.levels.ERROR
    )
    return
  end

  pi.send_raw({ type = "prompt", message = message }, function(err, resp)
    if err then return end
    if resp and resp.ok then
      vim.notify("Sent to pi", vim.log.levels.INFO)
    else
      vim.notify("pi error: " .. (resp and resp.error or "unknown"), vim.log.levels.ERROR)
    end
  end)
end

--- The reference the current context contributes. Pure.
--- @param context "selection"|"file"
--- @param data table
--- @return string
local function reference_text(context, data)
  if data.file == "" then
    return "(no file)"
  end
  if context == "selection" then
    return string.format("@%s lines %d-%d", data.file, data.start_line or 0, data.end_line or 0)
  end
  return "@" .. data.file
end

--- Display rows taken by `lines` in a pane `width` columns wide.
--- @param lines string[]
--- @param width integer
--- @return integer
local function wrapped_rows(lines, width)
  local rows = 0
  for _, line in ipairs(lines) do
    rows = rows + math.max(1, math.ceil(vim.fn.strdisplaywidth(line) / math.max(1, width - 1)))
  end
  return rows
end

--- Capture the visual selection line range, if any.
--- @return table|nil
local function capture_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  if start_pos[2] == 0 and end_pos[2] == 0 then
    return nil
  end
  return { start_line = start_pos[2], end_line = end_pos[2] }
end

--- Open the prompt float.
--- @param opts { default_context: "selection"|"file"|nil }|nil
function M.open(opts)
  opts = opts or {}

  local source_buf = vim.api.nvim_get_current_buf()
  local data = { file = vim.fn.expand("%:.") }
  local selection = capture_selection()
  if selection then
    data.start_line = selection.start_line
    data.end_line = selection.end_line
  end
  local has_selection = selection ~= nil

  local context = opts.default_context or "file"
  if context == "selection" and not has_selection then
    context = "file"
  end
  if not vim.tbl_contains(CONTEXTS, context) then
    context = "file"
  end

  local modified = vim.api.nvim_buf_is_valid(source_buf) and vim.bo[source_buf].modified

  -- The reference pane carries the reference plus a notice when the referenced
  -- file is stale (unsaved edits) or absent.
  local function reference_lines()
    local lines = { reference_text(context, data) }
    if data.file == "" then
      lines[#lines + 1] = "⚠ no file on disk; pi gets the prompt only"
    elseif modified then
      lines[#lines + 1] = "⚠ unsaved changes; pi will read the saved file"
    end
    return lines
  end

  -- Accent highlights, matching the plugin's dialog.
  local accent_hl = vim.api.nvim_get_hl(0, { name = "Function", link = false })
  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  vim.api.nvim_set_hl(0, "PiNvimBorder", { fg = accent_hl.fg, bg = normal_hl.bg })
  vim.api.nvim_set_hl(0, "PiNvimTitle", { fg = accent_hl.fg, bg = normal_hl.bg })

  -- Layout: one centered column, reference pane directly above the prompt pane.
  local pane_w = math.min(vim.o.columns - 4, math.max(40, math.floor(vim.o.columns * 0.6)))
  local col = math.max(0, math.floor((vim.o.columns - pane_w) / 2))
  local max_prompt_h = math.min(10, math.max(3, vim.o.lines - 10))
  local ref_h = math.max(1, math.min(4, wrapped_rows(reference_lines(), pane_w)))
  -- Center the group using its maximum footprint so prompt growth stays inside.
  local top_row = math.max(1, math.floor((vim.o.lines - (ref_h + 2 + max_prompt_h + 2)) / 2))
  local prompt_row = top_row + ref_h + 2

  local ref_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[ref_buf].buftype = "nofile"
  vim.bo[ref_buf].bufhidden = "wipe"

  local prompt_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[prompt_buf].buftype = "nofile"
  vim.bo[prompt_buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(prompt_buf, 0, -1, false, { "" })

  local ref_win = vim.api.nvim_open_win(ref_buf, false, {
    relative = "editor",
    width = pane_w,
    height = ref_h,
    row = top_row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " reference ",
    title_pos = "center",
    zindex = 50,
    noautocmd = true,
    focusable = false,
  })
  vim.wo[ref_win].wrap = true
  vim.wo[ref_win].winhl = "NormalFloat:Normal,FloatBorder:PiNvimBorder,FloatTitle:PiNvimTitle"

  local prompt_win = vim.api.nvim_open_win(prompt_buf, true, {
    relative = "editor",
    width = pane_w,
    height = 1,
    row = prompt_row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " prompt ",
    title_pos = "center",
    zindex = 51,
    noautocmd = true,
  })
  vim.wo[prompt_win].wrap = true
  vim.wo[prompt_win].winhl = "NormalFloat:Normal,FloatBorder:PiNvimBorder,FloatTitle:PiNvimTitle"

  local closed = false

  local function close()
    if closed then return end
    closed = true
    vim.cmd("noautocmd stopinsert")
    pcall(vim.api.nvim_win_close, prompt_win, true)
    pcall(vim.api.nvim_win_close, ref_win, true)
    pcall(vim.api.nvim_buf_delete, prompt_buf, { force = true })
    pcall(vim.api.nvim_buf_delete, ref_buf, { force = true })
  end

  local function render_reference()
    if not vim.api.nvim_buf_is_valid(ref_buf) then return end
    local lines = reference_lines()
    local h = math.max(1, math.min(4, wrapped_rows(lines, pane_w)))
    vim.bo[ref_buf].modifiable = true
    vim.api.nvim_buf_set_lines(ref_buf, 0, -1, false, lines)
    vim.bo[ref_buf].modifiable = false
    if vim.api.nvim_win_is_valid(ref_win) then
      vim.api.nvim_win_set_height(ref_win, h)
    end
    if vim.api.nvim_win_is_valid(prompt_win) then
      pcall(vim.api.nvim_win_set_config, prompt_win, { row = top_row + h + 2 })
    end
  end

  -- Grow the prompt pane with its content, up to the reserved maximum.
  local function resize_prompt()
    if not vim.api.nvim_win_is_valid(prompt_win) then return end
    local lines = vim.api.nvim_buf_get_lines(prompt_buf, 0, -1, false)
    local rows = wrapped_rows(lines, pane_w)
    vim.api.nvim_win_set_height(prompt_win, math.max(1, math.min(max_prompt_h, rows)))
  end

  local function cycle()
    context = M.next_context(context, has_selection)
    render_reference()
  end

  local function send()
    local lines = vim.api.nvim_buf_get_lines(prompt_buf, 0, -1, false)
    local prompt = vim.fn.trim(table.concat(lines, "\n"))
    local message = M.compose(context, vim.tbl_extend("force", data, { prompt = prompt }))
    if message == "" then
      vim.notify("Nothing to send", vim.log.levels.WARN)
      return
    end
    close()
    M.deliver(message)
  end

  render_reference()

  local kopts = { buffer = prompt_buf, noremap = true, silent = true, nowait = true }
  vim.keymap.set("i", "<CR>", send, kopts)
  vim.keymap.set("i", "<C-j>", function()
    -- Insert a literal line break without re-triggering the <CR> mapping.
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-j>", true, false, true), "n", false)
  end, kopts)
  vim.keymap.set({ "i", "n" }, "<Tab>", cycle, kopts)
  vim.keymap.set({ "i", "n" }, "<Esc>", close, kopts)
  vim.keymap.set({ "i", "n" }, "<C-c>", close, kopts)

  vim.api.nvim_create_autocmd({ "TextChangedI", "TextChanged" }, {
    buffer = prompt_buf,
    callback = resize_prompt,
  })

  vim.api.nvim_create_autocmd("BufLeave", {
    buffer = prompt_buf,
    once = true,
    callback = function()
      vim.schedule(close)
    end,
  })

  vim.cmd("noautocmd startinsert!")
end

return M
