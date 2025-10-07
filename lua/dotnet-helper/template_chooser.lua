local M = {}
local templates = require("dotnet-helper.templates")

local options = {
  {
    label = "Class",
    cmd = function()
      templates.class()
    end,
  },
  {
    label = "Controller",
    cmd = function()
      templates.api_controller()
    end,
  },
  {
    label = "Property",
    cmd = function()
      templates.property()
    end,
  },
  {
    label = "Method",
    cmd = function()
      templates.method()
    end,
  },
}

function M.show()
  vim.ui.select(options, {
    prompt = "Choose a template:",
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
