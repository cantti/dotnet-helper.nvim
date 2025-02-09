local M = {}

local options = {
  {
    label = "New: C# class",
    cmd = require("cshelper.templates").class,
  },
  {
    label = "New: C# Api Controller",
    cmd = require("cshelper.templates").apicontroller,
  },
  {
    label = "Build",
    cmd = require("cshelper.build").execute,
  },
  {
    label = "Clean",
    cmd = require("cshelper.clean").execute,
  },
  {
    label = "Secrets: edit",
    cmd = require("cshelper.secrets").edit,
  },
  {
    label = "Secrets: list",
    cmd = require("cshelper.secrets").list,
  },
  {
    label = "Fix namespace: buffer, update usings",
    cmd = function()
      require("cshelper.fix_ns").fix_ns({ mode = "buffer", update_usings = true })
    end,
  },
  {
    label = "Fix namespace: buffer, do not update usings",
    cmd = function()
      require("cshelper.fix_ns").fix_ns({ mode = "buffer", update_usings = false })
    end,
  },
  {
    label = "Fix namespace: directory, update usings",
    cmd = function()
      require("cshelper.fix_ns").fix_ns({ mode = "directory", update_usings = true })
    end,
  },
  {
    label = "Fix namespace: directory, do not update usings",
    cmd = function()
      require("cshelper.fix_ns").fix_ns({ mode = "directory", update_usings = false })
    end,
  },
}

function M.show()
  vim.ui.select(options, {
    prompt = "Choose an option:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    choice.cmd()
  end)
end

return M
