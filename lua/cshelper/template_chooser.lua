local M = {}
local templates = require("cshelper.templates")

local options = {
  {
    label = "New class",
    cmd = function()
      templates.class()
    end,
  },
  {
    label = "New api controller",
    cmd = function()
      templates.api_controller()
    end,
  },
  {
    label = "New property",
    cmd = function()
      templates.property()
    end,
  },
  {
    label = "New method",
    cmd = function()
      templates.property()
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
