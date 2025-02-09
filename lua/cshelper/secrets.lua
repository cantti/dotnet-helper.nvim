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

local function open_secrets_json(project_path)
  -- create secrets if does not exist
  vim.system({ "dotnet", "user-secrets", "init", "-p", project_path }):wait()
  local secrets_path = assert(get_secrets_path(project_path), "secrets file not found")
  if not fs.file_exists(secrets_path) then
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
  local function get_secrets_tbl()
    local output = vim.system({ "dotnet", "user-secrets", "list", "-p", project_path }):wait()
    local secrets_tbl = {}
    if string.match(output.stdout, "=") then
      for secret in string.gmatch(output.stdout, "(.-)\n") do
        local key, value = string.match(secret, "(.-) = (.+)")
        table.insert(secrets_tbl, { key = key, value = value })
      end
    end
    return secrets_tbl
  end
  local secrets = get_secrets_tbl()
  if not vim.tbl_isempty(secrets) then
    vim.ui.select(secrets, {
      prompt = "Choose secret:",
      format_item = function(item)
        return string.format("%s = %s", item.key, item.value)
      end,
    }, function(choice)
      if not choice then
        return
      end
      open_secrets_json(project_path)
      vim.fn.search('"' .. choice.key .. '"')
    end)
  else
    vim.notify("No secrets configured for the project", vim.log.levels.WARN)
  end
end

function M.edit()
  local targets = utils.get_projects(false)
  if vim.tbl_count(targets) == 1 then
    open_secrets_json(targets[1])
  else
    vim.ui.select(targets, {
      prompt = "Choose project:",
      format_item = function(item)
        return fs.relative_path(item)
      end,
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
      format_item = function(item)
        return fs.relative_path(item)
      end,
    }, function(choice)
      if not choice then
        return
      end
      list_secrets(choice)
    end)
  end
end

return M
