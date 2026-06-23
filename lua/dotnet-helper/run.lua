local utils = require("dotnet-helper.utils")
local fs = require("dotnet-helper.fs")
local a = require("dotnet-helper.async")
local runner = require("dotnet-helper.runner")

local M = {}
local H = {}

H.target = nil
H.extra_args = ""

M.run = a.async(function()
  H.target = utils.prompt_project("Choose project:", H.target, false)
  if not H.target then
    return
  end

  H.extra_args = a.input({ prompt = "Additional args: ", default = H.extra_args })
  if H.extra_args == nil then
    return
  end

  utils.notify("Running " .. fs.relative_path(H.target) .. "...")
  local args = { "dotnet", "run", "--project", H.target }
  if not utils.is_empty(H.extra_args) then
    table.insert(args, "--")
    vim.list_extend(args, vim.split(H.extra_args, "%s+", { trimempty = true }))
  end
  runner.run(args)
end)

return M
