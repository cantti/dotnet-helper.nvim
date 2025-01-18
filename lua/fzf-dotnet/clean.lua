local utils = require("fzf-dotnet.utils")

local M = {}

function M.clean_project_or_solution()
  local targets = utils.get_projects(vim.fn.getcwd(), true)
  require("fzf-lua").fzf_exec(targets, {
    winopts = {
      title = "Select project or solution",
    },
    actions = {
      ["default"] = function(selected)
        vim.cmd("! dotnet clean " .. selected[1])
      end,
    },
  })
end

function M.clean()
  vim.cmd("! dotnet clean")
end

return M
