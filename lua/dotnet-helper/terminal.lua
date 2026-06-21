local utils = require("dotnet-helper.utils")
local plugin = require("dotnet-helper")
local a = require("dotnet-helper.async")

local M = {}

local function get_opts()
  return (plugin.opts and plugin.opts.terminal) or {}
end

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

  local opts = get_opts()
  local position = opts.position
  vim.cmd(position .. " split")
  win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(win, opts.height)
  return win
end

---@param win integer
---@return integer
local function create_output_buffer(win)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "log"
  pcall(vim.api.nvim_buf_set_var, buf, "dotnet_helper_terminal", true)
  vim.api.nvim_win_set_buf(win, buf)
  return buf
end

---@param buf integer
---@param text string
local function set_output(buf, text)
  local normalized = text:gsub("\r\n", "\n")
  local lines = vim.split(normalized, "\n", { plain = true, trimempty = false })
  if vim.tbl_isempty(lines) then
    lines = { "" }
  end

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

---@param args string[]
---@param opts table?
---@return boolean|nil
---@return string? err
M.run = function(args, opts)
  opts = opts or {}

  local win = ensure_window()
  local buf = create_output_buffer(win)

  local output = a.system(args)

  local full_output = output.stdout or ""
  if output.stderr and output.stderr ~= "" then
    if full_output ~= "" then
      full_output = full_output .. "\n"
    end
    full_output = full_output .. output.stderr
  end

  set_output(buf, full_output)

  if output.code == 0 then
    utils.notify(opts.success_message or "Command completed")
    return true, nil
  end

  local msg = (output.stderr and output.stderr ~= "" and output.stderr) or output.stdout or "Command failed"
  if opts.notify_on_error ~= false then
    utils.notify(opts.error_message or msg, vim.log.levels.ERROR)
  end
  return nil, msg
end

return M
