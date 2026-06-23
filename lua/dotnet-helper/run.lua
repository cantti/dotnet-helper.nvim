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

  H.extra_args_str = a.input({ prompt = "Additional args: ", default = H.extra_args_str })

  utils.notify("Running " .. fs.relative_path(H.target) .. "...")
  local args = { "dotnet", "run", "--project", H.target, "--" }
  vim.list_extend(args, vim.split(H.extra_args, " "))
  runner.run(args)
end)

return M
