local utils = require("cshelper.utils")
local fs = require("cshelper.fs")

local M = {}
local H = {}

H.updated_ns = 0

function H.reset_stats()
  H.updated_ns = 0
end

function H.notify_stats()
  vim.notify("Updated namespaces: " .. H.updated_ns, vim.log.levels.INFO)
end

function H.get_files_not_opened(dir)
  local buffers = utils.get_valid_buffers()
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

function M.fix_ns_buf(opts)
  H.reset_stats()
  local buf = vim.api.nvim_get_current_buf()
  local filepath = vim.api.nvim_buf_get_name(buf)
  local res = H.fix_ns(utils.read(buf), filepath)
  if res.updated then
    utils.replace_lines(buf, res.lines)
  end
  H.notify_stats()
end

function M.fix_ns_dir(opts)
  vim.ui.input({ prompt = "Enter directory: ", default = fs.cwd(), completion = "dir" }, function(dir)
    H.reset_stats()

    local curr_buf = vim.api.nvim_get_current_buf()

    -- convert choice to abs path
    dir = fs.abs_path(dir)

    -- update in buffers
    local buffers = utils.get_valid_buffers_in_dir(dir)

    for _, buf in ipairs(buffers) do
      local res = H.fix_ns(utils.read(buf.no), buf.name)
      if res.updated then
        utils.replace_lines(buf.no, res.lines)
      end
    end

    -- update in files
    local files = H.get_files_not_opened(dir)

    for _, filepath in ipairs(files) do
      -- read without opening buffer
      local res = H.fix_ns(fs.read(filepath), filepath)
      if res.updated then
        utils.open_and_replace_lines(filepath, res.lines)
      end
    end

    -- restore old buf
    vim.api.nvim_set_current_buf(curr_buf)

    H.notify_stats()
  end)
end

return M
