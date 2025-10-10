local utils = require("dotnet-helper.utils")
local fs = require("dotnet-helper.fs")
local a = require("dotnet-helper.async")

local M = {}
local H = {}

--- @param output table
--- @param prefix "data"|"info"
H.notify = function(output, prefix)
  if output.code == 0 then
    vim.notify(utils.filter_dotnet_output(output.stdout, prefix), vim.log.levels.INFO)
  else
    local msg = (output.stderr ~= "" and output.stderr) or output.stdout
    msg = utils.filter_dotnet_output(msg, "error")
    vim.notify(msg, vim.log.levels.ERROR)
  end
end

H.prompt_project = function(prompt)
  local projects = utils.get_projects(false)
  if #projects == 0 then
    vim.notify("No projects found in this workspace.", vim.log.levels.WARN)
  elseif #projects == 1 then
    return projects[1]
  else
    return a.select(projects, {
      prompt = prompt,
      format_item = function(item)
        return fs.relative_path(item)
      end,
    })
  end
end

H.migration_add = function()
  local project = H.prompt_project("Choose project:")
  local startup = H.prompt_project("Choose startup project:")
  local name = a.input({ prompt = "Migration name: " })
  local args = { "dotnet", "ef", "migrations", "add", "--prefix-output", "-p", project, "-s", startup, name }
  local output = a.system(args)
  H.notify(output, "info")
end

H.migration_remove = function()
  local project = H.prompt_project("Choose project:")
  local startup = H.prompt_project("Choose startup project:")
  local args = { "dotnet", "ef", "migrations", "remove", "--force", "--prefix-output", "-p", project, "-s", startup }
  local output = a.system(args)
  H.notify(output, "info")
end

H.migration_list = function()
  local project = H.prompt_project("Choose project:")
  local startup = H.prompt_project("Choose startup project:")
  local args = { "dotnet", "ef", "migrations", "list", "--prefix-output", "-p", project, "-s", startup }
  local output = a.system(args)
  H.notify(output, "data")
end

M.migrations = a.async(function()
  local action = a.select({ "Add", "Remove", "List" }, {
    prompt = "Choose action:",
  })
  if not package then
    return
  end
  if action == "Add" then
    H.migration_add()
  end
  if action == "Remove" then
    H.migration_remove()
  end
  if action == "List" then
    H.migration_list()
  end
end)

return M
