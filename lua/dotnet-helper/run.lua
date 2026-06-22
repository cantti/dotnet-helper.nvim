local utils = require("dotnet-helper.utils")
local fs = require("dotnet-helper.fs")
local a = require("dotnet-helper.async")
local runner = require("dotnet-helper.runner")

local M = {}
local H = {}

H.target = nil

M.run = a.async(function()
  H.target = utils.prompt_project("Choose project:", H.target, false)
  if not H.target then
    return
  end

  utils.notify("Running " .. fs.relative_path(H.target) .. "...")
  local args = { "dotnet", "run", "--project", H.target }
  runner.run(args)
end)

return M
