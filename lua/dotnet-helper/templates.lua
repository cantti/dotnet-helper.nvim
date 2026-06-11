local fs = require("dotnet-helper.fs")
local ns = require("dotnet-helper.ns")

local M = {}

local function get_ident()
  return vim.fn["repeat"](" ", vim.opt.shiftwidth:get())
end

local function get_class_name()
  return fs.get_file_name_without_ext(fs.current_file_path())
end

local function get_namespace()
  return ns.compute_namespace(fs.current_file_path())
end

local function insert(lines, buf)
  buf = buf or vim.api.nvim_get_current_buf()
  local row = vim.api.nvim_win_get_cursor(0)[1]

  local start, stop = row, row
  local cur = vim.api.nvim_buf_get_lines(buf, row - 1, row, false)[1] or ""
  if cur:match("^%s*$") then
    -- replace the empty current line
    start, stop = row - 1, row
  end

  local tgt_row, tgt_col

  for iLine, line in ipairs(lines) do
    -- count how many spaces at the beginning of the line
    local _, spaces_count = string.find(line, "^%s*")

    -- replace spaces with ident
    -- two spaces = one ident
    if spaces_count > 0 then
      line = string.gsub(line, "^%s*", string.rep(get_ident(), spaces_count / 2))
    end

    -- add offset based on current row indent
    line = string.rep(" ", vim.fn.indent(row)) .. line

    local col = string.find(line, "$0")
    if col then
      tgt_row = start + iLine
      tgt_col = col
      line = string.gsub(line, "$0", "")
    end

    lines[iLine] = line
  end

  vim.api.nvim_buf_set_lines(buf, start, stop, false, lines)

  if tgt_row and tgt_col then
    vim.api.nvim_win_set_cursor(0, { tgt_row, tgt_col })
  end
end

---@class InsertClassOpts
---@field name? string
---@field block_ns? boolean
---@field buf? number

---@param opts? InsertClassOpts Options for generating the class code.
function M.class(opts)
  opts = opts or {}
  if opts.block_ns then
    insert({
      "namespace " .. get_namespace(),
      "{",
      "  public class " .. (opts.name or get_class_name()),
      "  {",
      "    $0",
      "  }",
      "}",
    }, opts.buf)
  else
    insert({
      "namespace " .. get_namespace() .. ";",
      "",
      "public class " .. (opts.name or get_class_name()),
      "{",
      "  $0",
      "}",
    }, opts.buf)
  end
end

function M.interface(opts)
  if opts.block_ns then
    insert({
      "namespace " .. get_namespace(),
      "{",
      "  public interface " .. (opts.name or get_class_name()),
      "  {",
      "    $0",
      "  }",
      "}",
    }, opts.buf)
  else
    insert({
      "namespace " .. get_namespace() .. ";",
      "",
      "public interface " .. (opts.name or get_class_name()),
      "{",
      "  $0",
      "}",
    }, opts.buf)
  end
end

return M
