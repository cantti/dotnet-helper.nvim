local M = {}
local fs = require("fzf-dotnet.fs")
local utils = require("fzf-dotnet.utils")

local function write(lines)
  local fpath = fs.current_file_path()
  local replacements = {
    namespace = utils.get_namespace_for_file(fpath),
    classname = fs.get_file_name_without_ext(fpath),
  }
  for i, _ in ipairs(lines) do
    for key, val in pairs(replacements) do
      lines[i] = string.gsub(lines[i], "%%" .. key .. "%%", val)
    end
  end
  vim.api.nvim_put(lines, "c", true, true)
end

function M.write_class(opts)
  opts = opts or {}
  opts.blockns = opts.blockns or false
  if opts.blockns then
    write({
      "namespace %namespace%",
      "{",
      "    public class %classname%",
      "    {",
      "    }",
      "}",
    })
  else
    write({
      "namespace %namespace%;",
      "",
      "public class %classname%",
      "{",
      "}",
    })
  end
end

function M.write_api_controller(opts)
  opts = opts or {}
  opts.blockns = opts.blockns or false
  if opts.blockns then
    write({
      "using Microsoft.AspNetCore.Http;",
      "using Microsoft.AspNetCore.Mvc;",
      "",
      "namespace %namespace% {",
      "",
      '    [Route("api/[controller]")]',
      "    [ApiController]",
      "    public class %classname% : ControllerBase",
      "    {",
      "    }",
      "}",
    })
  else
    write({
      "using Microsoft.AspNetCore.Http;",
      "using Microsoft.AspNetCore.Mvc;",
      "",
      "namespace %namespace%;",
      "",
      '[Route("api/[controller]")]',
      "[ApiController]",
      "public class %classname% : ControllerBase",
      "{",
      "}",
    })
  end
end

return M
