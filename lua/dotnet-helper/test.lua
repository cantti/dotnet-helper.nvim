local utils = require("dotnet-helper.utils")
local fs = require("dotnet-helper.fs")
local a = require("dotnet-helper.async")
local runner = require("dotnet-helper.runner")

local M = {}
local H = {}

H.target = nil

M.run_project_tests = function(project)
  local args = { "dotnet", "test", project }
  return runner.run(args, {
    notify_on_error = false,
  })
end

M.test = a.async(function()
  H.target = utils.prompt_project("Choose project/solution:", H.target, true)
  if not H.target then
    return
  end

  utils.notify("Running tests for " .. fs.relative_path(H.target) .. "...")
  M.run_project_tests(H.target)
end)

return M
