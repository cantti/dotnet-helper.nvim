local utils = require("cshelper.utils")
local fs = require("cshelper.fs")

local M = {}
local H = {}

local function run(cmd, on_done)
  vim.system(
    cmd,
    { text = true },
    vim.schedule_wrap(function(out)
      on_done(out)
    end)
  )
end

---@param cb fun(project: string)
function H.project_prompt(cb)
  local targets = utils.get_projects(false)
  if #targets == 1 then
    cb(targets[1])
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
      cb(choice)
    end)
  end
end

---@class SecretItem
---@field key string
---@field value string

---@param project string
---@param secrets SecretItem[]
function H.prompt_secret(project, secrets)
  if not secrets or vim.tbl_isempty(secrets) then
    vim.notify("No secrets configured for the project", vim.log.levels.WARN)
    return
  end

  -- show keys only to avoid leaking values
  vim.ui.select(
    secrets,
    {
      prompt = "Choose secret:",
      format_item = function(item)
        return string.format("%s = %s", item.key, item.value)
      end,
    },
    vim.schedule_wrap(function(choice)
      if not choice then
        return
      end
      H.open_secrets_json(project)
      -- jump after the file is opened/current
      -- very-nomagic search for the exact "key"
      local pattern = [[\V"]] .. choice.key:gsub("\\", "\\\\"):gsub('"', '\\"') .. [["]]
      vim.fn.search(pattern)
    end)
  )
end

---@param project string
---@param cb fun(secrets: SecretItem[])
function H.list_secrets(project, cb)
  run({ "dotnet", "user-secrets", "list", "-p", project }, function(output)
    local secrets = {}
    local out = output.stdout or ""
    if out:find("=") then
      -- robust split handling \r?\n
      for line in (out .. "\n"):gmatch("(.-)\r?\n") do
        local key, value = line:match("^(.-)%s*=%s*(.+)$")
        if key and value then
          table.insert(secrets, { key = key, value = value })
        end
      end
    end
    cb(secrets)
  end)
end

---@param project string
---@return string|nil
function H.get_secrets_path(project)
  local out = vim
    .system({
      "dotnet",
      "user-secrets",
      "list",
      "--verbose",
      "-p",
      project,
    }, { text = true })
    :wait()
  -- be tolerant with wording and endings; escape dot
  local path = string.match(out.stdout, "Secrets file path (.-)%.\n")
  return path
end

---@param project string
function H.open_secrets_json(project)
  vim.system({ "dotnet", "user-secrets", "init", "-p", project }):wait()
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

function M.list()
  H.project_prompt(function(project)
    H.list_secrets(project, function(secrets)
      H.prompt_secret(project, secrets)
    end)
  end)
end

function M.edit()
  H.project_prompt(H.open_secrets_json)
end

return M
