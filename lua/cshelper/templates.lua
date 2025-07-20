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

    -- add offset based on current row indent, skipping first line, because it is already idented
    if iLine > 1 then
      line = string.rep(" ", vim.fn.indent(utils.get_cur_row())) .. line
    end

    if not new_pos.found then
      local col = string.find(line, "%%c%%", 1)
      if col then
        new_pos.found = true
        new_pos.row = utils.get_cur_row() + iLine - 1
        if #lines == 1 then
          dd(utils.get_cur_col())
          new_pos.col = utils.get_cur_col() + col
        else
          new_pos.col = col
        end
        -- if end of the line, replace with space, for set pos to work correctly
        -- otherwise just remove
        -- helps when called from normal mode and cursor cannot be set after last not white space
        line = string.gsub(line, "%%c%%$", " ")
        line = string.gsub(line, "%%c%%", "")
      end
    end

    lines[iLine] = line
  end

  -- third parameter true to make very obvious how it work in normal mode
  vim.api.nvim_put(lines, "c", true, false)

  -- set cursor
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
      "    %c%",
      "  }",
      "}",
    })
  else
    write({
      "namespace %namespace%;",
      "",
      "public class %classname%",
      "{",
      "  %c%",
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
      "    %c%",
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
      "  %c%",
      "}",
    })
  end
end

function M.property(opts)
  opts = vim.tbl_deep_extend("keep", opts or {}, {
    required = true,
  })
  vim.ui.input({ prompt = "Enter property name: ", default = "NewProperty" }, function(name)
    vim.ui.input({ prompt = "Required?: ", default = "y" }, function(required)
      if required == "y" then
        write({
          "ttttttttt",
          "public required " .. name .. "%c% { get; set; }",
        })
      else
        write({
          "public " .. name .. " { get; set; }%c%",
        })
      end
    end)
  end)
end

function M.method(opts)
  opts = vim.tbl_deep_extend("keep", opts or {}, {
    required = true,
  })
  vim.ui.input({ prompt = "Enter method name: ", default = "NewMethod" }, function(name)
    write({
      "public void " .. name .. "()",
      "{",
      "  %c%",
      "}",
    })
  end)
end
return M
