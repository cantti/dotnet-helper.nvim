local fs = require("dotnet-helper.fs")
local ns = require("dotnet-helper.ns")

local M = {}

local function get_ident()
  return vim.fn["repeat"](" ", vim.opt.shiftwidth:get())
end

local function ask(questions, callback)
  local answers = {}
  local function _ask(iQuestion)
    local question = questions[iQuestion]
    vim.ui.input({ prompt = question.prompt .. ": ", default = question.default }, function(value)
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

---@param opts InsertClassOpts Options for generating the class code.
function M.insert_class(opts)
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

function M.class()
  ask({
    question("Enter class name", get_class_name(), "name"),
    question("Use block namespace?", "n", "block_ns", true),
  }, M.insert_class)
end

---@param opts InsertClassOpts Options for generating the class code.
function M.insert_interface(opts)
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

function M.interface()
  ask({
    question("Enter interface name", get_class_name(), "name"),
    question("Use block namespace?", "n", "block_ns", true),
  }, M.insert_interface)
end

function M.api_controller()
  ask({
    question("Enter controller name", fs.get_file_name_without_ext(fs.current_file_path()), "name"),
    question("Use block namespace", "n", "block_ns", true),
  }, function(answers)
    if answers.block_ns then
      insert({
        "using Microsoft.AspNetCore.Mvc;",
        "",
        "namespace %namespace%",
        "{",
        '  [Route("api/[controller]")]',
        "  [ApiController]",
        "  public class " .. (answers.name or get_class_name()) .. " : ControllerBase",
        "  {",
        "    $0",
        "  }",
        "}",
      })
    else
      insert({
        "using Microsoft.AspNetCore.Mvc;",
        "",
        "namespace %namespace%;",
        "",
        '[Route("api/[controller]")]',
        "[ApiController]",
        "public class " .. (answers.name or get_class_name()) .. " : ControllerBase",
        "{",
        "  $0",
        "}",
      })
    end
  end)
end

function M.property()
  ask({
    question("Enter property name", "NewProperty", "name"),
    question("Enter type", "string", "type"),
    question("Required", "y", "required", true),
  }, function(answers)
    local required_str = ""
    if answers.required then
      required_str = "required "
    end
    insert({ "public " .. required_str .. answers.type .. " " .. answers.name .. " { get; set; }$0" })
  end)
end

function M.method()
  ask({
    question("Enter method name", "NewMethod", "name"),
    question("Public", "n", "public", true),
    question("Async", "n", "async", true),
  }, function(answers)
    local return_str = "void"
    if answers.async then
      return_str = "async Task"
    end
    local mod_string = "private"
    if answers.public then
      mod_string = "public"
    end
    insert({
      mod_string .. " " .. return_str .. " " .. answers.name .. "()",
      "{",
      "  $0",
      "}",
    })
  end)
end

return M
