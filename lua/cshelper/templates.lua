local fs = require("cshelper.fs")
local utils = require("cshelper.utils")

local M = {}

local function get_ident()
  return vim.fn["repeat"](" ", vim.opt.shiftwidth:get())
end

local function ask(questions, callback)
  local answers = {}
  local function _ask(iQuestion)
    local question = questions[iQuestion]
    vim.ui.input({ prompt = question.prompt, default = question.default }, function(value)
      if question.bool then
        value = string.lower(value)
        answers[question.key] = value == "y" or value == "yes"
      else
        answers[question.key] = value
      end
      if iQuestion ~= #questions then
        _ask(iQuestion + 1)
      else
        callback(answers)
      end
    end)
  end
  _ask(1)
end

local function question(prompt, default, key, bool)
  return {
    prompt = prompt,
    default = default,
    key = key,
    bool = bool,
  }
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
      local col = string.find(line, "%%c%%")
      if col then
        new_pos.found = true
        new_pos.row = utils.get_cur_row() + iLine - 1
        if #lines == 1 then
          -- we isert in *after* mode, so no need -1
          new_pos.col = utils.get_cur_col() + col
        else
          new_pos.col = col
        end
        line = string.gsub(line, "%%c%%", "")
      end
    end

    lines[iLine] = line
  end

  -- third param true work best here
  -- very obvious in normal mode
  -- in insert mode works correct at the end of the line. last char does not exist yet, so it inserts *after* previous.
  vim.api.nvim_put(lines, "c", true, false)

  -- set cursor
  if new_pos.found then
    vim.cmd("startinsert")
    utils.set_pos(new_pos.row, new_pos.col)
  end
end

function M.class()
  ask({
    question("Enter class name:", fs.get_file_name_without_ext(fs.current_file_path()), "name"),
    question("Use block namespace?", "n", "block_ns", true),
  }, function(answers)
    if answers.block_ns then
      write({
        "namespace %namespace%",
        "{",
        "  public class " .. answers.name,
        "  {",
        "    %c%",
        "  }",
        "}",
      })
    else
      write({
        "namespace %namespace%;",
        "",
        "public class " .. answers.name,
        "{",
        "  %c%",
        "}",
      })
    end
  end)
end

function M.api_controller()
  ask({
    question("Enter controller name:", fs.get_file_name_without_ext(fs.current_file_path()), "name"),
    question("Use block namespace?", "n", "block_ns", true),
  }, function(answers)
    if answers.block_ns then
      write({
        "using Microsoft.AspNetCore.Mvc;",
        "",
        "namespace %namespace%",
        "{",
        '  [Route("api/[controller]")]',
        "  [ApiController]",
        "  public class " .. answers.name .. " : ControllerBase",
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
        "public class " .. answers.name .. " : ControllerBase",
        "{",
        "  %c%",
        "}",
      })
    end
  end)
end

function M.property()
  ask({
    question("Enter property name:", "NewProperty", "name"),
    question("Enter type:", "string", "type"),
    question("Required?:", "y", "required", true),
  }, function(answers)
    local required_str = ""
    if answers.required then
      required_str = "required "
    end
    write({ "public " .. required_str .. answers.type .. " " .. answers.name .. " { get; set; }%c%" })
  end)
end

function M.method()
  ask({
    question("Enter method name:", "NewMethod", "name"),
    question("Public:", "n", "public", true),
    question("Async:", "n", "async", true),
  }, function(answers)
    local return_str = "void"
    if answers.async then
      return_str = "async Task"
    end
    local mod_string = "private"
    if answers.public then
      mod_string = "public"
    end
    write({
      mod_string .. " " .. return_str .. " " .. answers.name .. "()",
      "{",
      "  %c%",
      "}",
    })
  end)
end

return M
