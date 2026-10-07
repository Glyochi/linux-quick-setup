-- Hand-rolled pi terminal split.
--
-- `:terminal` names its buffer `term://{cwd}//{pid}:{cmd}`, so the command below
-- produces a buffer name ending in `:pi --tui-mode regular -c`. The pi-nvim
-- bridge's `prompt()` matches `:pi` / `:pi `, so sends land in this split with
-- no extra plumbing. `regular` TUI mode writes to the split's scrollback instead
-- of taking over the alternate screen, which keeps Neovim scrolling usable.
local M = {}

M.cmd = "pi --tui-mode regular -c"

--- True when a terminal buffer name belongs to the pi command.
--- @param name string|nil
--- @return boolean
function M.is_pi_terminal(name)
  if type(name) ~= "string" or name == "" then
    return false
  end
  name = name:lower()
  return name:match(":pi$") ~= nil or name:match(":pi%s") ~= nil
end

--- Locate the pi terminal buffer, plus its window when it is visible.
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

--- Open the pi terminal in a right-hand split, hide it, or restore it.
--- Hiding keeps the pi process alive, so restoring resumes the same conversation.
function M.toggle()
  local buf, win = M.find()

  if buf and win then
    pcall(vim.api.nvim_win_hide, win)
    return
  end

  if buf then
    vim.cmd("botright vsplit")
    vim.api.nvim_win_set_buf(0, buf)
    vim.cmd("startinsert")
    return
  end

  vim.cmd("botright vsplit")
  vim.cmd("terminal " .. M.cmd)
  vim.cmd("startinsert")
end

return M
