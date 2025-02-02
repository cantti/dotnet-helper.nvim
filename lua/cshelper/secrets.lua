local utils = require("cshelper.utils")
local fs = require("cshelper.fs")

local M = {}

local function get_secrets_path(project_path)
  local output = vim
    .system({
      "dotnet",
      "user-secrets",
      "list",
      "--verbose",
      "-p",
      project_path,
    }, { text = true })
    :wait()
  local path = string.match(output.stdout, "Secrets file path (.-)%.\n")
  return path
end

local function get_secrets_tbl(project_path)
  local output = vim.system({ "dotnet", "user-secrets", "list", "-p", project_path }):wait()
  local secrets_tbl = {}
  for secret in string.gmatch(output.stdout, "(.-)\n") do
    local key, value = string.match(secret, "(.-) = (.+)")
    table.insert(secrets_tbl, { key = key, value = value })
  end
  return secrets_tbl
end
local function open_secrets_json(project_path)
  -- create secrets if does not exist
  vim.system({ "dotnet", "user-secrets", "init", "-p", project_path }):wait()

  local secrets_path = assert(get_secrets_path(project_path), "secrets file not found")

  if not fs.file_exists(secrets_path) then
    -- create file if does not exist
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, secrets_path)
    vim.api.nvim_buf_set_option(buf, "filetype", "json")
    vim.api.nvim_set_current_buf(buf)
    local lines = {
      "{",
      "  ",
      "}",
    }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  else
    -- if file exists, just open
    vim.cmd("edit " .. secrets_path)
  end
end

local function list_secrets(project_path)
  local secrets = get_secrets_tbl(project_path)
  local choices = vim.tbl_map(function(x)
    return x.key .. " = " .. x.value
  end, secrets)
  vim.ui.select(choices, {
    prompt = "Choose secret:",
  }, function(choice)
    if not choice then
      return
    end
    open_secrets_json(project_path)
    local key = string.match(choice, "(.-) = ")
    vim.fn.search('"' .. key .. '"')
  end)
end

function M.edit()
  local targets = utils.get_projects(false)
  if vim.tbl_count(targets) == 1 then
    open_secrets_json(targets[1])
  else
    vim.ui.select(targets, {
      prompt = "Choose project:",
    }, function(choice)
      if not choice then
        return
      end
      open_secrets_json(choice)
    end)
  end
end

function M.list()
  local targets = utils.get_projects(false)
  if vim.tbl_count(targets) == 1 then
    list_secrets(targets[1])
  else
    vim.ui.select(targets, {
      prompt = "Choose project:",
    }, function(choice)
      if not choice then
        return
      end
      list_secrets(choice)
    end)
  end
end

return M
