local utils = require("dotnet-helper.utils")
local a = require("dotnet-helper.async")

local M = {}
local H = {}

H.project = nil
H.startup = nil

--- @param output table
H.notify = function(output)
  if output.code == 0 then
    utils.notify(output.stdout)
  else
    local msg = (output.stderr ~= "" and output.stderr) or output.stdout
    utils.notify(msg, vim.log.levels.ERROR)
  end
end

H.migration_add = function()
  H.project = utils.prompt_project("Choose project:", H.project)
  if not H.project then
    return
  end
  H.startup = utils.prompt_project("Choose startup project:", H.startup)
  if not H.startup then
    return
  end
  local name = a.input({ prompt = "Migration name: " })
  if not name then
    return
  end
  local args = { "dotnet", "ef", "migrations", "add", "-p", H.project, "-s", H.startup, name }
  utils.notify("Adding migration...")
  local output = a.system(args)
  H.notify(output)
end

H.migration_remove = function()
  H.project = utils.prompt_project("Choose project:", H.project)
  if not H.project then
    return
  end
  H.startup = utils.prompt_project("Choose startup project:", H.startup)
  if not H.startup then
    return
  end
  local args = { "dotnet", "ef", "migrations", "remove", "--force", "-p", H.project, "-s", H.startup }
  utils.notify("Removing migration...")
  local output = a.system(args)
  H.notify(output)
end

H.migration_list = function()
  H.project = utils.prompt_project("Choose project:", H.project)
  if not H.project then
    return
  end
  H.startup = utils.prompt_project("Choose startup project:", H.startup)
  if not H.startup then
    return
  end
  local args = { "dotnet", "ef", "migrations", "list", "-p", H.project, "-s", H.startup }
  utils.notify("Listing migrations...")
  local output = a.system(args)
  H.notify(output)
end

H.has_pending_changes = function()
  H.project = utils.prompt_project("Choose project:", H.project)
  if not H.project then
    return
  end
  H.startup = utils.prompt_project("Choose startup project:", H.startup)
  if not H.startup then
    return
  end
  local args = { "dotnet", "ef", "migrations", "has-pending-model-changes", "-p", H.project, "-s", H.startup }
  utils.notify("Checking for pending model changes...")
  local output = a.system(args)
  H.notify(output)
end

H.database_update = function()
  H.project = utils.prompt_project("Choose project:", H.project)
  if not H.project then
    return
  end
  H.startup = utils.prompt_project("Choose startup project:", H.startup)
  if not H.startup then
    return
  end
  local args = { "dotnet", "ef", "database", "update", "-p", H.project, "-s", H.startup }
  utils.notify("Updating database...")
  local output = a.system(args)
  H.notify(output)
end

M.ef = a.async(function()
  local action = a.select({
    "Migrations: add",
    "Migrations: remove",
    "Migrations: list",
    "Migrations: has pending model changes",
    "Database: update",
  }, {
    prompt = "Choose action:",
  })
  if action == "Migrations: add" then
    H.migration_add()
  end
  if action == "Migrations: remove" then
    H.migration_remove()
  end
  if action == "Migrations: list" then
    H.migration_list()
  end
  if action == "Migrations: has pending model changes" then
    H.has_pending_changes()
  end
  if action == "Database: update" then
    H.database_update()
  end
end)

return M
