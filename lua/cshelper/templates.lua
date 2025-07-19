local fs = require("cshelper.fs")
local utils = require("cshelper.utils")

local M = {}

local function get_ident()
  return vim.fn["repeat"](" ", vim.opt.shiftwidth:get())
end

local function write(lines)
  local new_pos = {
    found = false,
    row = 0,
    col = 0,
  }
  local fpath = fs.current_file_path()
  local replacements = {
    namespace = utils.get_namespace_for_file(fpath),
    classname = fs.get_file_name_without_ext(fpath),
  }

  for iLine, line in ipairs(lines) do
    for key, val in pairs(replacements) do
      line = string.gsub(line, "%%" .. key .. "%%", val)
    end

    -- count how many spaces at the beginning of the line
    local _, spaces_count = string.find(line, "^%s*")

    -- replace spaces with ident
    -- two spaces = one ident
    if spaces_count > 0 then
      line = string.gsub(line, "^%s*", string.rep(get_ident(), spaces_count / 2))
    end

    if not new_pos.found then
      local col = string.find(line, "|")
      if col then
        new_pos.found = true
        new_pos.row = utils.get_cur_row() + iLine - 1
        if #lines == 1 then
          new_pos.col = utils.get_cur_col() + col - 1
        else
          new_pos.col = col
        end
        line = string.gsub(line, "|", " ")
      end
    end
    lines[iLine] = line
  end

  vim.api.nvim_put(lines, "c", false, false)

  if new_pos.found then
    utils.set_pos(new_pos.row, new_pos.col)
    vim.cmd("startinsert")
  end
end

function M.class(opts)
  opts = vim.tbl_deep_extend("keep", opts or {}, {
    use_block_ns = false,
  })
  if opts.use_block_ns then
    write({
      "namespace %namespace%",
      "{",
      "  public class %classname%",
      "  {",
      "    |",
      "  }",
      "}",
    })
  else
    write({
      "namespace %namespace%;",
      "",
      "public class %classname%",
      "{",
      "  |",
      "}",
    })
  end
end

function M.api_controller(opts)
  opts = vim.tbl_deep_extend("keep", opts or {}, {
    use_block_ns = false,
  })
  if opts.use_block_ns then
    write({
      "using Microsoft.AspNetCore.Mvc;",
      "",
      "namespace %namespace%",
      "{",
      '  [Route("api/[controller]")]',
      "  [ApiController]",
      "  public class %classname% : ControllerBase",
      "  {",
      "    |",
      "  }",
      "}",
    })
  else
    write({
      "using Microsoft.AspNetCore.Mvc;",
      "",
      "namespace %namespace%;",
      "",
      '[Route("api/[controller]")]',
      "[ApiController]",
      "public class %classname% : ControllerBase",
      "{",
      "  |",
      "}",
    })
  end
end

function M.property(opts)
  opts = vim.tbl_deep_extend("keep", opts or {}, {
    required = true,
  })
  if opts.required then
    write({
      "public required |{get; set;}",
    })
  else
    write({
      "public |{get; set;}",
    })
  end
end
return M
