local utils = require("dotnet-helper.utils")
local plugin = require("dotnet-helper")

local M = {}

local opts = (plugin.opts and plugin.opts.terminal) or {}

---@return integer|nil
local function get_shared_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    local ok, is_terminal = pcall(vim.api.nvim_buf_get_var, buf, "dotnet_helper_terminal")
    if ok and is_terminal == true then
      return win
    end
  end

  return nil
end

---@return integer
local function ensure_window()
  local win = get_shared_window()
  if win then
    vim.api.nvim_set_current_win(win)
    return win
  end

  local position = opts.position or "botright"
  vim.cmd(position .. " split")
  win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(win, opts.height or 14)
  return win
end

---@param args string[]
---@return boolean|nil
---@return string? err
M.run = function(args)
  local win = ensure_window()

  local buf = vim.api.nvim_create_buf(true, false)
  vim.bo[buf].bufhidden = "hide"
  pcall(vim.api.nvim_buf_set_var, buf, "dotnet_helper_terminal", true)
  vim.api.nvim_win_set_buf(win, buf)

  local job_id = vim.fn.jobstart(args, {
    term = true,
    on_exit = function(_, code)
      vim.schedule(function()
        if code == 0 then
          utils.notify("Command completed")
        else
          utils.notify("Command failed", vim.log.levels.ERROR)
        end
      end)
    end,
  })

  if job_id <= 0 then
    return nil, "Failed to start terminal command"
  end

  if opts.enter_insert == true then
    vim.cmd("startinsert")
  end
  return true, nil
end

return M
