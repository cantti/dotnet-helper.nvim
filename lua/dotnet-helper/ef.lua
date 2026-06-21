local utils = require("dotnet-helper.utils")
local a = require("dotnet-helper.async")
local runner = require("dotnet-helper.runner")

local M = {}
local H = {}

H.project = nil
H.startup = nil

---@param args string[]
---@param start_msg string
---@param success_msg string
---@param error_msg string
H.run_action = function(args, start_msg, success_msg, error_msg)
  utils.notify(start_msg)
  local ok, err = runner.run(args, {
    success_message = success_msg,
    error_message = error_msg,
  })

  if not ok then
    utils.notify(err or "Failed to start command", vim.log.levels.ERROR)
  end
end

H.prompt_project_and_startup = function()
  H.project = utils.prompt_project("Choose project:", H.project)
  if not H.project then
    return false
  end

  H.startup = utils.prompt_project("Choose startup project:", H.startup)
  if not H.startup then
    return false
  end

  return true
end

M.migration_add = function()
  if not H.prompt_project_and_startup() then
    return
  end
  local name = a.input({ prompt = "Migration name: " })
  if not name then
    return
  end
  local args = { "dotnet", "ef", "migrations", "add", "-p", H.project, "-s", H.startup, name }
  H.run_action(args, "Adding migration...", "Migration added", "Migration add failed")
end

H.migration_remove = function()
  if not H.prompt_project_and_startup() then
    return
  end
  local args = { "dotnet", "ef", "migrations", "remove", "--force", "-p", H.project, "-s", H.startup }
  H.run_action(args, "Removing migration...", "Migration removed", "Migration remove failed")
end

H.migration_list = function()
  if not H.prompt_project_and_startup() then
    return
  end
  local args = { "dotnet", "ef", "migrations", "list", "-p", H.project, "-s", H.startup }
  H.run_action(args, "Listing migrations...", "Migration list completed", "Migration list failed")
end

H.has_pending_changes = function()
  if not H.prompt_project_and_startup() then
    return
  end
  local args = { "dotnet", "ef", "migrations", "has-pending-model-changes", "-p", H.project, "-s", H.startup }
  H.run_action(args, "Checking for pending model changes...", "Check completed", "Check failed")
end

H.database_update = function()
  if not H.prompt_project_and_startup() then
    return
  end
  local args = { "dotnet", "ef", "database", "update", "-p", H.project, "-s", H.startup }
  H.run_action(args, "Updating database...", "Database updated", "Database update failed")
end

H.database_drop = function()
  if not H.prompt_project_and_startup() then
    return
  end

  local force_drop = a.select({ "No", "Yes" }, {
    prompt = "Force drop database?",
  })
  if not force_drop then
    return
  end

  local args = { "dotnet", "ef", "database", "drop", "-p", H.project, "-s", H.startup }
  if force_drop == "Yes" then
    table.insert(args, "--force")
  end

  H.run_action(args, "Dropping database...", "Database dropped", "Database drop failed")
end

H.dbcontext_info = function()
  if not H.prompt_project_and_startup() then
    return
  end

  local args = { "dotnet", "ef", "dbcontext", "info", "-p", H.project, "-s", H.startup }
  H.run_action(args, "Getting DbContext info...", "DbContext info completed", "DbContext info failed")
end

H.dbcontext_list = function()
  if not H.prompt_project_and_startup() then
    return
  end

  local args = { "dotnet", "ef", "dbcontext", "list", "-p", H.project, "-s", H.startup }
  H.run_action(args, "Listing DbContexts...", "DbContext list completed", "DbContext list failed")
end

H.migration_script = function()
  if not H.prompt_project_and_startup() then
    return
  end

  local from = a.input({ prompt = "From migration (optional): " })
  if from == nil then
    return
  end

  local to = a.input({ prompt = "To migration (optional): " })
  if to == nil then
    return
  end

  local idempotent = a.select({ "No", "Yes" }, {
    prompt = "Generate idempotent script?",
  })
  if not idempotent then
    return
  end

  local args = { "dotnet", "ef", "migrations", "script" }
  if from ~= "" then
    table.insert(args, from)
  end
  if to ~= "" then
    table.insert(args, to)
  end
  table.insert(args, "-p")
  table.insert(args, H.project)
  table.insert(args, "-s")
  table.insert(args, H.startup)
  if idempotent == "Yes" then
    table.insert(args, "--idempotent")
  end

  H.run_action(args, "Generating migration script...", "Migration script generated", "Migration script failed")
end

M.ef = a.async(function()
  local actions = {
    { label = "Migrations: add", handler = M.migration_add },
    { label = "Migrations: remove", handler = H.migration_remove },
    { label = "Migrations: list", handler = H.migration_list },
    { label = "Migrations: has pending model changes", handler = H.has_pending_changes },
    { label = "Migrations: script", handler = H.migration_script },
    { label = "Database: update", handler = H.database_update },
    { label = "Database: drop", handler = H.database_drop },
    { label = "DbContext: info", handler = H.dbcontext_info },
    { label = "DbContext: list", handler = H.dbcontext_list },
  }

  local labels = {}
  local handlers = {}

  for _, action in ipairs(actions) do
    table.insert(labels, action.label)
    handlers[action.label] = action.handler
  end

  local selected = a.select(labels, {
    prompt = "Choose action:",
  })

  local handler = handlers[selected]
  if handler then
    handler()
  end
end)

return M
