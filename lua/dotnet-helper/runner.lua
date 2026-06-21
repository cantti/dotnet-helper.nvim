local utils = require("dotnet-helper.utils")
local plugin = require("dotnet-helper")

local M = {}

local function get_opts()
  return (plugin.opts and plugin.opts.terminal) or {}
end

---@return integer|nil
local function get_shared_window()
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.b[buf].dotnet_helper_terminal == true then
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
    vim.wo[win].number = false
    vim.wo[win].relativenumber = false
    return win
  end

  local opts = get_opts()
  local position = opts.position or "botright"
  vim.cmd(position .. " split")
  win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_height(win, opts.height or 14)
  vim.wo[win].number = false
  vim.wo[win].relativenumber = false
  return win
end

---@param win integer
---@param source_win integer
---@return integer
local function create_output_buffer(win, source_win)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.bo[buf].buftype = "nofile"
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.bo[buf].filetype = "log"
  vim.b[buf].dotnet_helper_terminal = true
  vim.b[buf].dotnet_helper_has_output = false
  vim.b[buf].dotnet_helper_source_win = source_win

  vim.keymap.set("n", "gf", function()
    local current_line = vim.api.nvim_get_current_line()
    local file, line_num = current_line:match("(%S+):line%s+(%d+)")

    if file == nil or file == "" then
      file = vim.fn.expand("<cfile>")
    else
      file = file:gsub("[,;%.%)%]]+$", "")
    end

    if file == nil or file == "" then
      return
    end

    if vim.fn.filereadable(file) ~= 1 then
      utils.notify("File not found: " .. file, vim.log.levels.WARN)
      return
    end

    local target_win = vim.b[buf].dotnet_helper_source_win
    if target_win and vim.api.nvim_win_is_valid(target_win) then
      vim.api.nvim_set_current_win(target_win)
    end

    vim.cmd("edit " .. vim.fn.fnameescape(file))

    if line_num then
      local line = tonumber(line_num)
      if line and line > 0 then
        vim.api.nvim_win_set_cursor(0, { line, 0 })
      end
    end
  end, { buffer = buf, silent = true, desc = "Open file under cursor" })

  vim.api.nvim_win_set_buf(win, buf)
  return buf
end

---@param buf integer
---@param lines string[]
local function append_lines(buf, lines)
  if not vim.api.nvim_buf_is_valid(buf) or vim.tbl_isempty(lines) then
    return
  end

  local first_write = vim.b[buf].dotnet_helper_has_output == false

  vim.bo[buf].modifiable = true
  if first_write then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.b[buf].dotnet_helper_has_output = true
  else
    vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
  end
  vim.bo[buf].modifiable = false

  local last = vim.api.nvim_buf_line_count(buf)
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_buf(win) == buf then
      vim.api.nvim_win_set_cursor(win, { last, 0 })
    end
  end
end

---@param buf integer
---@param stash string
---@param data string[]
---@return string
local function push_data(buf, stash, data)
  if not data then
    return stash
  end

  local to_append = {}
  for i, chunk in ipairs(data) do
    local part = chunk or ""
    if i == 1 then
      part = stash .. part
    end

    if i < #data then
      table.insert(to_append, part)
    else
      stash = part
    end
  end

  append_lines(buf, to_append)
  return stash
end

---@class RunnerRunOpts
---@field success_message string?
---@field error_message string?
---@field notify_on_error boolean?

---@param args string[]
---@param opts RunnerRunOpts?
---@return boolean|nil
---@return string? err
M.run = function(args, opts)
  opts = opts or {}

  local source_win = vim.api.nvim_get_current_win()
  local win = ensure_window()
  local buf = create_output_buffer(win, source_win)
  local stdout_stash = ""
  local stderr_stash = ""

  local job_id = vim.fn.jobstart(args, {
    stdout_buffered = false,
    stderr_buffered = false,
    on_stdout = function(_, data)
      stdout_stash = push_data(buf, stdout_stash, data)
    end,
    on_stderr = function(_, data)
      stderr_stash = push_data(buf, stderr_stash, data)
    end,
    on_exit = function(_, code)
      vim.schedule(function()
        if stdout_stash ~= "" then
          append_lines(buf, { stdout_stash })
          stdout_stash = ""
        end
        if stderr_stash ~= "" then
          append_lines(buf, { stderr_stash })
          stderr_stash = ""
        end

        if code == 0 then
          utils.notify(opts.success_message or "Command completed")
          return
        end

        if opts.notify_on_error ~= false then
          utils.notify(opts.error_message or "Command failed", vim.log.levels.ERROR)
        end
      end)
    end,
  })

  if job_id <= 0 then
    return nil, "Failed to start output command"
  end

  return true, nil
end

return M
