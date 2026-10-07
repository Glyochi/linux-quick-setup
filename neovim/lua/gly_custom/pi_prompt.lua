-- Context-aware floating prompt for pi.
--
-- Layout is context-left / prompt-right. The left pane is read-only and shows the
-- exact text that will be included; the right pane is the prompt and grows as it
-- is typed. The composed message uses the same wording as carderne/pi-nvim. A
-- visible pi split receives it directly; with no split, or a hidden one, it goes
-- over the plugin's socket path to the running pi instance (see `M.deliver`).
local M = {}

local CONTEXTS = { "selection", "buffer", "file" }

--- Compose the message exactly like the plugin's own send commands.
--- Pure: no editor state is read here.
--- @param context "selection"|"buffer"|"file"
--- @param ctx table { prompt, file, abs_file, ft, text, content, start_line, end_line }
--- @return string
function M.compose(context, ctx)
  ctx = ctx or {}
  local prompt = vim.trim(ctx.prompt or "")
  local file = ctx.file or ""
  local abs_file = ctx.abs_file or ""
  local ft = ctx.ft or ""
  local fence = "```" .. ft

  if context == "selection" then
    local text = ctx.text or ""
    if text == "" then
      return prompt
    end
    local header = string.format("%s lines %d-%d", file, ctx.start_line or 0, ctx.end_line or 0)
    if prompt == "" then
      return string.format("Look at this code from %s:\n\n%s\n%s\n```", header, fence, text)
    end
    return string.format("%s\n\nFrom %s:\n%s\n%s\n```", prompt, header, fence, text)
  elseif context == "buffer" then
    if file == "" then
      return prompt
    end
    local content = ctx.content or ""
    if prompt == "" then
      return string.format("Look at this file %s:\n\n%s\n%s\n```", file, fence, content)
    end
    return string.format("%s\n\nFile: %s\n%s\n%s\n```", prompt, file, fence, content)
  end

  -- file
  if abs_file == "" then
    return prompt
  end
  if prompt == "" then
    return string.format("Look at this file: %s", abs_file)
  end
  return string.format("File: %s\n\n%s", abs_file, prompt)
end

--- Next context in the cycle. Without a visual selection, `selection` is skipped.
--- Pure.
--- @param current string
--- @param has_selection boolean
--- @return string
function M.next_context(current, has_selection)
  if has_selection then
    if current == "selection" then
      return "buffer"
    elseif current == "buffer" then
      return "file"
    end
    return "selection"
  end
  if current == "buffer" then
    return "file"
  end
  return "buffer"
end

--- Deliver a composed message.
---
--- A visible pi split receives it directly (the plugin pastes into the terminal
--- buffer). When no split is open, or the split is hidden, the message goes over
--- the plugin's socket path to the running pi instance and is submitted there;
--- a hidden split stays hidden. Transport itself stays in the plugin.
--- @param message string
function M.deliver(message)
  local ok, pi = pcall(require, "pi-nvim")
  if not ok then
    vim.notify("pi-nvim is not available", vim.log.levels.ERROR)
    return
  end

  local term_buf, term_win = require("gly_custom.pi_terminal").find()
  if term_buf and not term_win then
    -- The split exists but is hidden: keep it hidden and use the socket.
    pi.send_raw({ type = "prompt", message = message }, function(err, resp)
      if err then return end
      if resp and resp.ok then
        vim.notify("Sent to pi", vim.log.levels.INFO)
      else
        vim.notify("pi error: " .. (resp and resp.error or "unknown"), vim.log.levels.ERROR)
      end
    end)
    return
  end

  -- No split, or a visible one: the plugin picks the terminal buffer when it is
  -- visible and the socket otherwise.
  pi.prompt(message)
end

--- The exact text the current context contributes (without the prompt).
--- @param context "selection"|"buffer"|"file"
--- @param data table
--- @return string
local function context_text(context, data)
  if context == "selection" then
    local header = string.format("%s lines %d-%d", data.file, data.start_line or 0, data.end_line or 0)
    return header .. "\n\n" .. "```" .. (data.ft or "") .. "\n" .. (data.text or "") .. "\n```"
  elseif context == "buffer" then
    if data.file == "" then
      return "(no file)"
    end
    return "File: " .. data.file .. "\n\n```" .. (data.ft or "") .. "\n" .. (data.content or "") .. "\n```"
  end
  if data.abs_file == "" then
    return "(no file)"
  end
  return "File: " .. data.abs_file
end

--- Capture the visual selection marks, if any.
--- @return table|nil
local function capture_selection()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  if start_pos[2] == 0 and end_pos[2] == 0 then
    return nil
  end
  local ok, lines = pcall(vim.fn.getregion, start_pos, end_pos, { type = vim.fn.visualmode() })
  if not ok or not lines or #lines == 0 then
    return nil
  end
  local text = table.concat(lines, "\n")
  if text == "" then
    return nil
  end
  return { text = text, start_line = start_pos[2], end_line = end_pos[2] }
end

--- Open the prompt float.
--- @param opts { default_context: "selection"|"buffer"|"file"|nil }|nil
function M.open(opts)
  opts = opts or {}

  local source_buf = vim.api.nvim_get_current_buf()
  local data = {
    file = vim.fn.expand("%:."),
    abs_file = vim.fn.expand("%:p"),
    ft = vim.bo.filetype,
    content = table.concat(vim.api.nvim_buf_get_lines(source_buf, 0, -1, false), "\n"),
  }
  local selection = capture_selection()
  if selection then
    data.text = selection.text
    data.start_line = selection.start_line
    data.end_line = selection.end_line
  end
  local has_selection = selection ~= nil

  local context = opts.default_context or "buffer"
  if context == "selection" and not has_selection then
    context = "buffer"
  end
  if not vim.tbl_contains(CONTEXTS, context) then
    context = "buffer"
  end

  -- Accent highlights, matching the plugin's dialog.
  local accent_hl = vim.api.nvim_get_hl(0, { name = "Function", link = false })
  local normal_hl = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
  vim.api.nvim_set_hl(0, "PiNvimBorder", { fg = accent_hl.fg, bg = normal_hl.bg })
  vim.api.nvim_set_hl(0, "PiNvimTitle", { fg = accent_hl.fg, bg = normal_hl.bg })

  -- Layout
  local gap = 2
  local total_w = math.min(vim.o.columns - 4, math.max(60, math.floor(vim.o.columns * 0.85)))
  local pane_w = math.floor((total_w - gap) / 2)
  local ctx_h = math.min(12, math.max(3, vim.o.lines - 12))
  local row = math.max(1, math.floor((vim.o.lines - (ctx_h + 2)) / 2))
  local col = math.max(0, math.floor((vim.o.columns - total_w) / 2))

  local ctx_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[ctx_buf].buftype = "nofile"
  vim.bo[ctx_buf].bufhidden = "wipe"

  local prompt_buf = vim.api.nvim_create_buf(false, true)
  vim.bo[prompt_buf].buftype = "nofile"
  vim.bo[prompt_buf].bufhidden = "wipe"
  vim.api.nvim_buf_set_lines(prompt_buf, 0, -1, false, { "" })

  local ctx_win = vim.api.nvim_open_win(ctx_buf, false, {
    relative = "editor",
    width = pane_w,
    height = ctx_h,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
    title = " context ",
    title_pos = "center",
    zindex = 50,
    noautocmd = true,
    focusable = false,
  })
  vim.wo[ctx_win].wrap = true
  vim.wo[ctx_win].winhl = "NormalFloat:Normal,FloatBorder:PiNvimBorder,FloatTitle:PiNvimTitle"

  local prompt_win = vim.api.nvim_open_win(prompt_buf, true, {
    relative = "editor",
    width = pane_w,
    height = 1,
    row = row,
    col = col + pane_w + gap,
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
    pcall(vim.api.nvim_win_close, ctx_win, true)
    pcall(vim.api.nvim_buf_delete, prompt_buf, { force = true })
    pcall(vim.api.nvim_buf_delete, ctx_buf, { force = true })
  end

  local function render_context()
    if not vim.api.nvim_buf_is_valid(ctx_buf) then return end
    local lines = vim.split(context_text(context, data), "\n", { plain = true })
    vim.bo[ctx_buf].modifiable = true
    vim.api.nvim_buf_set_lines(ctx_buf, 0, -1, false, lines)
    vim.bo[ctx_buf].modifiable = false
    pcall(vim.api.nvim_win_set_config, ctx_win, {
      title = " context: " .. context .. " ",
      title_pos = "center",
    })
  end

  -- Grow the prompt pane with its content, up to the context pane's height.
  local function resize_prompt()
    if not vim.api.nvim_win_is_valid(prompt_win) then return end
    local lines = vim.api.nvim_buf_get_lines(prompt_buf, 0, -1, false)
    local rows = 0
    for _, line in ipairs(lines) do
      rows = rows + math.max(1, math.ceil(#line / math.max(1, pane_w - 1)))
    end
    vim.api.nvim_win_set_height(prompt_win, math.max(1, math.min(ctx_h, rows)))
  end

  local function scroll_context(delta)
    if not vim.api.nvim_win_is_valid(ctx_win) then return end
    local view = vim.api.nvim_win_call(ctx_win, vim.fn.winsaveview)
    local topline = math.max(1, (view.topline or 1) + delta)
    vim.api.nvim_win_call(ctx_win, function()
      vim.fn.winrestview({ topline = topline })
    end)
  end

  local function cycle()
    context = M.next_context(context, has_selection)
    render_context()
    resize_prompt()
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

  render_context()

  local kopts = { buffer = prompt_buf, noremap = true, silent = true, nowait = true }
  vim.keymap.set("i", "<CR>", send, kopts)
  vim.keymap.set("i", "<C-j>", function()
    -- Insert a literal line break without re-triggering the <CR> mapping.
    vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<C-j>", true, false, true), "n", false)
  end, kopts)
  vim.keymap.set({ "i", "n" }, "<Tab>", cycle, kopts)
  vim.keymap.set("i", "<C-d>", function() scroll_context(math.floor(ctx_h / 2)) end, kopts)
  vim.keymap.set("i", "<C-u>", function() scroll_context(-math.floor(ctx_h / 2)) end, kopts)
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
