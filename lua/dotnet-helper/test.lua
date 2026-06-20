local utils = require("dotnet-helper.utils")
local fs = require("dotnet-helper.fs")
local a = require("dotnet-helper.async")
local terminal = require("dotnet-helper.terminal")

local M = {}
local H = {}

H.project = nil

---@param project string
---@return boolean|nil
---@return string? err
M.run_project_tests = function(project)
  local args = { "dotnet", "test", project }
  return terminal.run(args, {
    success_message = "Tests passed",
    error_message = "Tests failed",
  })
end

M.test = a.async(function()
  H.project = utils.prompt_project("Choose project/solution:", H.project, true)
  if not H.project then
    return
  end

  utils.notify("Running tests for " .. fs.relative_path(H.project) .. "...")
  local ok, err = M.run_project_tests(H.project)
  if not ok then
    utils.notify(err or "Failed to run tests", vim.log.levels.ERROR)
  end
end)

return M
