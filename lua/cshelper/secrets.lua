local utils = require("cshelper.utils")
local fs = require("cshelper.fs")

local Secrets = {}
Secrets.__index = Secrets

function Secrets:new()
  local obj = setmetatable({}, Secrets)
  obj.project = nil
  return obj
end

function Secrets:_project_prompt(cb)
  local targets = utils.get_projects(false)
  if #targets == 1 then
    self.project = targets[1]
    cb()
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
      self.project = choice
      cb()
    end)
  end
end

function Secrets:_list_secrets()
  local function get_secrets_tbl()
    local output = vim.system({ "dotnet", "user-secrets", "list", "-p", self.project }):wait()
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
      self:_open_secrets_json()
      vim.fn.search('"' .. choice.key .. '"')
    end)
  else
    vim.notify("No secrets configured for the project", vim.log.levels.WARN)
  end
end

function Secrets:_get_secrets_path()
  local output = vim
    .system({
      "dotnet",
      "user-secrets",
      "list",
      "--verbose",
      "-p",
      self.project,
    }, { text = true })
    :wait()
  local path = string.match(output.stdout, "Secrets file path (.-)%.\n")
  return path
end

function Secrets:_open_secrets_json()
  -- create secrets if does not exist
  vim.system({ "dotnet", "user-secrets", "init", "-p", self.project }):wait()
  local secrets_path = assert(self:_get_secrets_path(), "secrets file not found")
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

function Secrets:list()
  self:_project_prompt(function()
    self:_list_secrets()
  end)
end

function Secrets:edit()
  self:_project_prompt(function()
    self:_open_secrets_json()
  end)
end

return Secrets
