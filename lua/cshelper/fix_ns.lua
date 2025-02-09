local utils = require("cshelper.utils")
local fs = require("cshelper.fs")

local M = {}

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
    end
  end

  return res
end

local function update_usings_in_cwd(old_ns, new_ns)
  local curr_buf = vim.api.nvim_get_current_buf()
  local all_files = utils.get_file_options(".", { "cs" })
  for _, filepath in ipairs(all_files) do
    filepath = fs.abs_path(filepath)
    -- ignore current file
    if fs.current_file_path() ~= fs.abs_path(filepath) then
      -- try updating ns in current buffers
      local found_in_buffers = false
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          local bufname = vim.api.nvim_buf_get_name(buf)
          if bufname == filepath then
            found_in_buffers = true
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local res = update_usings(lines, old_ns, new_ns)
            if res.updated then
              vim.api.nvim_buf_set_lines(buf, 0, -1, false, res.lines)
            end
            break
          end
        end
      end

      -- read file and if not found
      if not found_in_buffers then
        local lines = read(filepath)
        local res = update_usings(lines, old_ns, new_ns)
        if res.updated then
          vim.cmd("edit " .. vim.fn.fnameescape(filepath))
          local buf = vim.api.nvim_get_current_buf()
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, res.lines)
        end
      end
    end
  end
  vim.api.nvim_set_current_buf(curr_buf)
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
      end
    end
    table.insert(res.lines, line)
  end
  return res
end

function M.fix_ns_document()
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  local res = fix_ns(lines, filepath)
  if res.updated then
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, res.lines)
    update_usings_in_cwd(res.old_ns, res.new_ns)
  end
  vim.notify("Namespace was updated", vim.log.levels.INFO)
end

function M.fix_ns_directory()
  -- local curr_buf = vim.api.nvim_get_current_buf()
  vim.ui.input({ prompt = "Enter directory: ", default = ".", completion = "dir" }, function(dir)
    local files = utils.get_file_options(dir, { "cs" })
    -- update namespace in files
    for _, filepath in ipairs(files) do
      filepath = fs.abs_path(filepath)
      -- try finding in buffers
      local found_in_buffers = false
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) then
          local bufname = vim.api.nvim_buf_get_name(buf)
          if bufname == filepath then
            found_in_buffers = true
            local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
            local res = fix_ns(lines, filepath)
            if res.updated then
              vim.api.nvim_buf_set_lines(buf, 0, -1, false, res.lines)
              update_usings_in_cwd(res.old_ns, res.new_ns)
            end
            break
          end
        end
      end
      -- read file if not found
      if not found_in_buffers then
        -- read without opening buffer
        local lines = read(filepath)
        local res = fix_ns(lines, filepath)
        if res.updated then
          vim.cmd("edit " .. vim.fn.fnameescape(filepath))
          local buf = vim.api.nvim_get_current_buf()
          vim.api.nvim_buf_set_lines(buf, 0, -1, false, res.lines)
          update_usings_in_cwd(res.old_ns, res.new_ns)
        end
      end
    end
  end)
end

return M
