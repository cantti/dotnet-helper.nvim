local utils = require("dotnet-helper.utils")
local fs = require("dotnet-helper.fs")
local a = require("dotnet-helper.async")
local terminal = require("dotnet-helper.terminal")

local M = {}
local H = {}

H.target = nil

M.build = a.async(function()
  H.target = utils.prompt_project("Choose project/solution:", H.target, true)
  if not H.target then
    return
  end

  utils.notify("Building " .. fs.relative_path(H.target) .. "...")
  local args = { "dotnet", "build", H.target }
  local ok, err = terminal.run(args)
  if not ok then
    utils.notify(err or "Failed to start build", vim.log.levels.ERROR)
  end
end)

return M
