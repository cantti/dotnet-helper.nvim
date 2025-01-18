local utils = require("fzf-dotnet.utils")

local M = {}

function M.build_project_or_solution()
  local targets = utils.get_projects(vim.fn.getcwd(), true)
  require("fzf-lua").fzf_exec(targets, {
    winopts = {
      title = "Select project or solution",
    },
    actions = {
      ["default"] = function(selected)
        vim.cmd("! dotnet build " .. selected[1])
      end,
    },
  })
end

function M.build_solution()
  local solution = utils.get_solution(vim.fn.getcwd())
  if solution then
    vim.cmd("! dotnet build " .. solution)
  end
end

return M
