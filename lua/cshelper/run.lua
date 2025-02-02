local utils = require("cshelper.utils")

local M = {}

local function run_project(project)
  vim.cmd("term dotnet run " .. project)
end

function M.execute()
  local targets = utils.get_projects(false)
  if vim.tbl_count(targets) == 1 then
    run_project(targets[1])
  else
    vim.ui.select(targets, {
      prompt = "Choose project or solution:",
    }, function(choice)
      if not choice then
        return
      end
      run_project(choice)
    end)
  end
end

return M
