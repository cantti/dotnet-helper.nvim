local utils = require("fzf-dotnet.utils")

local M = {}

local function run_project(project)
  vim.cmd("bel split | terminal dotnet run " .. project)
end

function M.run_project()
  local targets = utils.get_projects(false)
  if vim.tbl_count(targets) == 1 then
    run_project(targets[1])
  else
    require("fzf-lua").fzf_exec(targets, {
      winopts = {
        title = "Select project or solution",
      },
      actions = {
        ["default"] = function(selected, opts)
          run_project(selected[1])
        end,
      },
    })
  end
end

return M
