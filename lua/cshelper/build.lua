local utils = require("cshelper.utils")

local M = {}

local function build(project)
  vim.cmd("term dotnet build " .. project)
end

function M.execute()
  local targets = utils.get_projects(true)
  vim.ui.select(targets, {
    prompt = "Choose project or solution:",
  }, function(choice)
    if not choice then
      return
    end
    build(choice)
  end)
end

return M
