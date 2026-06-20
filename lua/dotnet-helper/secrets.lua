local utils = require("dotnet-helper.utils")
local fs = require("dotnet-helper.fs")
local a = require("dotnet-helper.async")

local M = {}
local H = {}

H.project = nil

---@param project string
---@return string|nil
H.get_user_secrets_id = function(project)
  for line in io.lines(project) do
    local id = string.match(line, "<UserSecretsId>([^<>]+)</UserSecretsId>")
    if id then
      return id
    end
  end
  return nil
end

---@param project string
---@return string|nil
---@return string? err
H.get_secrets_path = function(project)
  local user_secrets_id = H.get_user_secrets_id(project)
  if not user_secrets_id then
    return nil, "no UserSecretsId found"
  end

  local root
  if fs.is_windows then
    root = fs.join_paths({ vim.env.APPDATA, "Microsoft", "UserSecrets" })
  else
    root = fs.join_paths({ vim.env.HOME, ".microsoft", "usersecrets" })
  end

  local path = fs.join_paths({ root, user_secrets_id, "secrets.json" })
  return path, nil
end

---@param project string
H.open_secrets_json = function(project)
  local init_output = a.system({ "dotnet", "user-secrets", "init", "-p", project })
  if init_output.code ~= 0 then
    local err = (init_output.stderr ~= "" and init_output.stderr) or "dotnet user-secrets init failed"
    utils.notify(err, vim.log.levels.WARN)
    return
  end

  local secrets_path, err = H.get_secrets_path(project)
  if not secrets_path then
    utils.notify(err or "secrets file not found", vim.log.levels.WARN)
    return
  end

  if not fs.file_exists(secrets_path) then
    local buf = vim.api.nvim_create_buf(true, false)
    vim.api.nvim_buf_set_name(buf, secrets_path)
    vim.bo[buf].filetype = "json"
    vim.api.nvim_set_current_buf(buf)
    local lines = {
      "{",
      "  ",
      "}",
    }
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  else
    -- if file exists, just open
    vim.cmd("edit " .. vim.fn.fnameescape(secrets_path))
  end
end

H.edit = a.async(function()
  H.project = utils.prompt_project("Choose project:", H.project)
  if not H.project then
    return
  end
  H.open_secrets_json(H.project)
end)

M.secrets = a.async(function()
  H.edit()
end)

return M
