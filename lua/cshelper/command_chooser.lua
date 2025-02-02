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
    label = "Fix namespace",
    cmd = require("cshelper.fix_ns").execute,
  },
}

local labels = vim.tbl_map(function(x)
  return x.label
end, options)

local function get_cmd(label)
  return vim.tbl_filter(function(x)
    return x.label == label
  end, options)[1].cmd
end

function M.show()
  vim.ui.select(labels, {
    prompt = "Choose an option:",
  }, function(choice)
    if not choice then
      return
    end
    get_cmd(choice)()
  end)
end

return M
