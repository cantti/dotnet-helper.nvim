local utils = require("dotnet-helper.utils")
local fs = require("dotnet-helper.fs")
local a = require("dotnet-helper.async")

local M = {}
local H = {}

H.project = nil

---@param target string
---@return string[]
M.build_test_args = function(target)
  return { "dotnet", "test", target }
end

---@param project string
---@return boolean|nil
---@return string? err
M.run_project_tests = function(project)
  local args = M.build_test_args(project)
  local output = a.system(args)

  if output.code == 0 then
    utils.notify(output.stdout)
    return true, nil
  end

  local msg = (output.stderr ~= "" and output.stderr) or output.stdout
  utils.notify(msg, vim.log.levels.ERROR)
  return nil, msg
end

M.test = a.async(function()
  H.project = utils.prompt_project("Choose project/solution:", H.project, true)
  if not H.project then
    return
  end

  utils.notify("Running tests for " .. fs.relative_path(H.project) .. "...")
  M.run_project_tests(H.project)
end)

return M
