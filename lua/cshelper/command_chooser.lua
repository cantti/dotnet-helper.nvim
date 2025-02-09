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
    label = "Fix namespace in buffer",
    cmd = require("cshelper.fix_ns").fix_ns_buf,
  },
  {
    label = "Fix namespace in directory",
    cmd = require("cshelper.fix_ns").fix_ns_dir,
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
