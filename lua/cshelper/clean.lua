local utils = require("cshelper.utils")

local M = {}

local function clean(project)
  vim.cmd("term dotnet clean " .. project)
end

function M.execute()
  local targets = utils.get_projects(true)
  vim.ui.select(targets, {
    prompt = "Choose project or solution:",
  }, function(choice)
    if not choice then
      return
    end
    clean(choice)
  end)
end

return M
