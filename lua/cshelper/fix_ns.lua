local utils = require("cshelper.utils")
local buf_utils = require("cshelper.buf_utils")
local fs = require("cshelper.fs")

local M = {}

local updated_ns = 0
local updated_usings = 0

local function reset_stats()
  updated_usings = 0
  updated_ns = 0
end

local function notify_stats()
  vim.notify("Updated namespaces: " .. updated_ns, vim.log.levels.INFO)
  vim.notify("Updated usings: " .. updated_usings, vim.log.levels.INFO)
end

local function get_files_not_opened(dir)
  local buffers = buf_utils.get_valid_buffers()
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
  local already_has_using = vim.tbl_contains(lines, function(x)
    return string.match(x, "using%s+" .. new_ns .. ";")
  end, { predicate = true })

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
  local buffers = buf_utils.get_valid_buffers()

  -- update usings for buffers
  for _, buf in ipairs(buffers) do
    local lines = buf_utils.read(buf.no)
    local res = update_usings(lines, old_ns, new_ns)
    if res.updated then
      buf_utils.replace_lines(buf.no, res.lines)
    end
  end

  -- find other files
  local files = get_files_not_opened(fs.cwd())

  for _, filepath in ipairs(files) do
    local lines = fs.read(filepath)
    local res = update_usings(lines, old_ns, new_ns)
    if res.updated then
      buf_utils.open_and_replace_lines(filepath, res.lines)
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

function M.fix_ns_buf()
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

function M.fix_ns_dir()
  vim.ui.input({ prompt = "Enter directory: ", default = fs.cwd(), completion = "dir" }, function(dir)
    reset_stats()

    local curr_buf = vim.api.nvim_get_current_buf()

    -- convert choice to abs path
    dir = fs.abs_path(dir)

    -- update in buffers
    local buffers = buf_utils.get_valid_buffers_in_dir(dir)

    for _, buf in ipairs(buffers) do
      local res = fix_ns(buf_utils.read(buf.no), buf.name)
      if res.updated then
        buf_utils.replace_lines(buf.no, res.lines)
        update_usings_cwd(res.old_ns, res.new_ns)
      end
    end

    -- update in files
    local files = get_files_not_opened(dir)

    for _, filepath in ipairs(files) do
      -- read without opening buffer
      local res = fix_ns(fs.read(filepath), filepath)
      if res.updated then
        buf_utils.open_and_replace_lines(filepath, res.lines)
        update_usings_cwd(res.old_ns, res.new_ns)
      end
    end

    -- restore old buf
    vim.api.nvim_set_current_buf(curr_buf)

    notify_stats()
  end)
end

return M
