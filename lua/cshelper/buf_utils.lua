local fs = require("cshelper.fs")
local M = {}

function M.get_valid_buffers()
  local result = {}
  for _, no in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(no) then
      table.insert(result, { no = no, name = vim.api.nvim_buf_get_name(no) })
    end
  end
  return result
end

function M.get_valid_buffers_in_dir(dir)
  return vim.tbl_filter(function(x)
    return vim.startswith(x.name, fs.abs_path(dir))
  end, M.get_valid_buffers())
end

function M.read(no)
  return vim.api.nvim_buf_get_lines(no, 0, -1, false)
end

function M.open_and_replace_lines(filepath, lines)
  vim.cmd("edit " .. vim.fn.fnameescape(filepath))
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
end

function M.replace_lines(no, lines)
  vim.api.nvim_buf_set_lines(no, 0, -1, false, lines)
end

return M
