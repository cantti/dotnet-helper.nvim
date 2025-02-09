local utils = require("cshelper.utils")
local buf_utils = require("cshelper.buf_utils")
local fs = require("cshelper.fs")

local M = {}
local H = {}

H.updated_ns = 0
H.updated_usings = 0

function H.reset_stats()
  H.updated_usings = 0
  H.updated_ns = 0
end

function H.notify_stats()
  vim.notify("Updated namespaces: " .. H.updated_ns, vim.log.levels.INFO)
  vim.notify("Updated usings: " .. H.updated_usings, vim.log.levels.INFO)
end

function H.get_files_not_opened(dir)
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

function H.update_usings(lines, old_ns, new_ns)
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
      H.updated_usings = H.updated_usings + 1
    end
  end

  return res
end

function H.update_usings_cwd(old_ns, new_ns)
  local buffers = buf_utils.get_valid_buffers()

  -- update usings for buffers
  for _, buf in ipairs(buffers) do
    local lines = buf_utils.read(buf.no)
    local res = H.update_usings(lines, old_ns, new_ns)
    if res.updated then
      buf_utils.replace_lines(buf.no, res.lines)
    end
  end

  -- find other files
  local files = H.get_files_not_opened(fs.cwd())

  for _, filepath in ipairs(files) do
    local lines = fs.read(filepath)
    local res = H.update_usings(lines, old_ns, new_ns)
    if res.updated then
      buf_utils.open_and_replace_lines(filepath, res.lines)
    end
  end
end

function H.fix_ns(lines, filepath)
  local new_ns = utils.get_namespace_for_file(filepath)
  local res = { updated = false, lines = {}, old_ns = nil, new_ns = new_ns }
  for _, line in ipairs(lines) do
    local old_ns = string.match(line, "namespace%s+([^;%s]+)")
    if old_ns and not res.updated then
      res.old_ns = old_ns
      if old_ns ~= new_ns then
        line = string.gsub(line, "namespace%s+[^;%s]+", "namespace " .. new_ns)
        res.updated = true
        H.updated_ns = H.updated_ns + 1
      end
    end
    table.insert(res.lines, line)
  end
  return res
end

function H.fix_ns_buf(opts)
  H.reset_stats()
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)
  local res = H.fix_ns(buf_utils.read(buf), filepath)
  if res.updated then
    buf_utils.replace_lines(buf, res.lines)
    if opts.update_usings then
      H.update_usings_cwd(res.old_ns, res.new_ns)
    end
  end
  H.notify_stats()
end

function H.fix_ns_dir(opts)
  vim.ui.input({ prompt = "Enter directory: ", default = fs.cwd(), completion = "dir" }, function(dir)
    H.reset_stats()

    local curr_buf = vim.api.nvim_get_current_buf()

    -- convert choice to abs path
    dir = fs.abs_path(dir)

    -- update in buffers
    local buffers = buf_utils.get_valid_buffers_in_dir(dir)

    for _, buf in ipairs(buffers) do
      local res = H.fix_ns(buf_utils.read(buf.no), buf.name)
      if res.updated then
        buf_utils.replace_lines(buf.no, res.lines)
        if opts.update_usings then
          H.update_usings_cwd(res.old_ns, res.new_ns)
        end
      end
    end

    -- update in files
    local files = H.get_files_not_opened(dir)

    for _, filepath in ipairs(files) do
      -- read without opening buffer
      local res = H.fix_ns(fs.read(filepath), filepath)
      if res.updated then
        buf_utils.open_and_replace_lines(filepath, res.lines)
        if opts.update_usings then
          H.update_usings_cwd(res.old_ns, res.new_ns)
        end
      end
    end

    -- restore old buf
    vim.api.nvim_set_current_buf(curr_buf)

    H.notify_stats()
  end)
end

function M.fix_ns(opts)
  opts = vim.tbl_deep_extend("keep", opts, {
    mode = "buffer",
    update_usings = true,
  })
  if opts.mode == "buffer" then
    H.fix_ns_buf(opts)
  elseif opts.mode == "directory" then
    H.fix_ns_dir(opts)
  end
end

return M
