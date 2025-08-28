local utils = require("cshelper.utils")
local fs = require("cshelper.fs")
local a = require("cshelper.async")

local M = {}
local H = {}

---@return string|nil
H.project_prompt = function()
  local targets = utils.get_projects(false)
  if #targets == 1 then
    return targets[1]
  else
    return a.select(targets, {
      prompt = "Choose project:",
      format_item = function(item)
        return fs.relative_path(item)
      end,
    })
  end
end

---@class SecretItem
---@field key string
---@field value string

---@param project string
---@param secrets SecretItem[]
H.prompt_secret = function(project, secrets)
  if not secrets or vim.tbl_isempty(secrets) then
    vim.notify("No secrets configured for the project", vim.log.levels.WARN)
    return
  end
  local choice = a.select(secrets, {
    prompt = "Choose secret:",
    format_item = function(item)
      return string.format("%s = %s", item.key, item.value)
    end,
  })
  if not choice then
    return
  end
  H.open_secrets_json(project)
  -- jump after the file is opened/current
  -- very-nomagic search for the exact "key"
  local pattern = [[\V"]] .. choice.key:gsub("\\", "\\\\"):gsub('"', '\\"') .. [["]]
  vim.fn.search(pattern)
end

---@param project string
---@return table? result
---@return string? err
H.list_secrets = function(project)
  local output = a.system({ "dotnet", "user-secrets", "list", "-p", project })
  if output.code ~= 0 then
    local err = (output and output.stderr ~= "" and output.stderr) or "dotnet secret list failed"
    return nil, err
  end
  local secrets = {}
  if string.match(output.stdout, "=") then
    for secret in string.gmatch(output.stdout, "(.-)\n") do
      local key, value = string.match(secret, "(.-) = (.+)")
      table.insert(secrets, { key = key, value = value })
    end
  end
  return secrets
end

---@param project string
---@return string|nil
---@return string? err
H.get_secrets_path = function(project)
  local output = a.system({
    "dotnet",
    "user-secrets",
    "list",
    "--verbose",
    "-p",
    project,
  })
  if output.code ~= 0 then
    local err = (output and output.stderr ~= "" and output.stderr) or "dotnet secret list failed"
    return nil, err
  end
  local path = string.match(output.stdout, "Secrets file path (.-)%.\n")
  if not path then
    return nil, "no secrets path found"
  end
  return path, nil
end

---@param project string
H.open_secrets_json = function(project)
  a.system({ "dotnet", "user-secrets", "init", "-p", project })
  local secrets_path = assert(H.get_secrets_path(project), "secrets file not found")
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

M.list = a.async(function()
  local project = H.project_prompt()
  if not project then
    return
  end
  local secrets = assert(H.list_secrets(project))
  H.prompt_secret(project, secrets)
end)

M.edit = a.async(function()
  local project = H.project_prompt()
  if not project then
    return
  end
  H.open_secrets_json(project)
end)

return M
