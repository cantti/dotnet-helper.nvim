local utils = require("cshelper.utils")
local fs = require("cshelper.fs")

local M = {}

local updated_ns = 0
local updated_usings = 0

local function read(filepath)
  local file = io.open(filepath, "r") -- Open file in read mode
  if not file then
    print("Error: Unable to open file " .. filepath)
    return nil
  end

  local lines = {} -- Table to store lines
  for line in file:lines() do
    table.insert(lines, line)
  end

  file:close() -- Close the file
  return lines -- Return table with file content
end

local function get_buffers()
  local result = {}
  for _, no in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(no) then
      table.insert(
        result,
        { no = no, name = vim.api.nvim_buf_get_name(no), lines = vim.api.nvim_buf_get_lines(no, 0, -1, false) }
      )
    end
  end
  return result
end

local function get_files_not_opened(dir, buffers)
  local result = {}
  local files = utils.get_file_options(dir, { "cs" })
  for _, filepath in ipairs(files) do
    local opened = vim.tbl_contains(buffers, function(x)
      return x.name == filepath
    end, { predicate = true })
    if not opened then
      table.insert(result, filepath)
    end
  end
  return result
end

local function update_usings(lines, old_ns, new_ns)
  local res = { updated = false, lines = {} }

  -- check if already has using
  local already_has_using = false
  for _, line in ipairs(lines) do
    if string.match(line, "using%s+" .. new_ns .. ";") then
      already_has_using = true
      break
    end
  end

  -- set res.lines and insert new using
  for _, line in ipairs(lines) do
    table.insert(res.lines, line)
    if not already_has_using and string.match(line, "using%s+" .. old_ns .. ";") then
      table.insert(res.lines, "using " .. new_ns .. ";")
      res.updated = true
      updated_usings = updated_usings + 1
    end
  end

  return res
end

local function update_usings_cwd(old_ns, new_ns)
  local buffers = get_buffers()

  for _, buf in ipairs(buffers) do
    local res = update_usings(buf.lines, old_ns, new_ns)
    if res.updated then
      vim.api.nvim_buf_set_lines(buf.no, 0, -1, false, res.lines)
    end
  end

  local files = get_files_not_opened(fs.cwd(), buffers)

  for _, filepath in ipairs(files) do
    local lines = read(filepath)
    local res = update_usings(lines, old_ns, new_ns)
    if res.updated then
      vim.cmd("edit " .. vim.fn.fnameescape(filepath))
      local buf = vim.api.nvim_get_current_buf()
      vim.api.nvim_buf_set_lines(buf, 0, -1, false, res.lines)
    end
  end
end

local function fix_ns(lines, filepath)
  local new_ns = utils.get_namespace_for_file(filepath)
  local res = { updated = false, lines = {}, old_ns = nil, new_ns = new_ns }
  for _, line in ipairs(lines) do
    local old_ns = string.match(line, "namespace%s+([^;%s]+)")
    if old_ns and not res.updated then
      res.old_ns = old_ns
      if old_ns ~= new_ns then
        line = string.gsub(line, "namespace%s+[^;%s]+", "namespace " .. new_ns)
        res.updated = true
        updated_ns = updated_ns + 1
      end
    end
    table.insert(res.lines, line)
  end
  return res
end

local function reset_stats()
  updated_usings = 0
  updated_ns = 0
end

local function notify_stats()
  vim.notify("Updated namespaces: " .. updated_ns, vim.log.levels.INFO)
  vim.notify("Updated usings: " .. updated_usings, vim.log.levels.INFO)
end

function M.fix_ns_document()
  reset_stats()
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local res = fix_ns(lines, filepath)
  if res.updated then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, res.lines)
    update_usings_cwd(res.old_ns, res.new_ns)
  end
  notify_stats()
end

function M.fix_ns_directory()
  vim.ui.input({ prompt = "Enter directory: ", default = fs.cwd(), completion = "dir" }, function(dir)
    reset_stats()

    local curr_buf = vim.api.nvim_get_current_buf()

    -- convert choice to abs path
    dir = fs.abs_path(dir)

    -- update in buffers
    local buffers = get_buffers()

    for _, buf in ipairs(buffers) do
      if vim.startswith(buf.name, dir) then
        local res = fix_ns(buf.lines, buf.name)
        if res.updated then
          vim.api.nvim_buf_set_lines(buf.no, 0, -1, false, res.lines)
          update_usings_cwd(res.old_ns, res.new_ns)
        end
      end
    end

    -- update in files
    local files = get_files_not_opened(dir, buffers)

    for _, filepath in ipairs(files) do
      -- read without opening buffer
      local lines = read(filepath)
      local res = fix_ns(lines, filepath)
      if res.updated then
        vim.cmd("edit " .. vim.fn.fnameescape(filepath))
        local buf = vim.api.nvim_get_current_buf()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, res.lines)
        update_usings_cwd(res.old_ns, res.new_ns)
      end
    end

    -- restore old buf
    vim.api.nvim_set_current_buf(curr_buf)

    notify_stats()
  end)
end

return M
