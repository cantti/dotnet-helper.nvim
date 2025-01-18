local utils = require("fzf-dotnet.utils")
local fs = require("fzf-dotnet.fs")

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
  local keys = {}
  for _, secret in ipairs(secrets) do
    table.insert(keys, secret.key)
  end
  require("fzf-lua").fzf_exec(keys, {
    winopts = {
      title = "Select secret",
    },
    fzf_opts = {
      ["--preview"] = function(selected)
        local contents = {}
        for _, secret in ipairs(secrets) do
          if secret.key == selected[1] then
            table.insert(contents, secret.value)
            break
          end
        end
        return contents
      end,
    },
    actions = {
      ["default"] = function(selected, opts)
        open_secrets_json(project_path)
        vim.fn.search('"' .. selected[1] .. '"')
      end,
    },
  })
end

function M.edit_secrets()
  local targets = utils.get_projects(vim.fn.getcwd(), false)
  require("fzf-lua").fzf_exec(targets, {
    winopts = {
      title = "Select project or solution",
    },
    actions = {
      ["default"] = function(selected, opts)
        open_secrets_json(selected[1])
      end,
    },
  })
end

function M.list_secrets()
  local targets = utils.get_projects(vim.fn.getcwd(), false)
  require("fzf-lua").fzf_exec(targets, {
    winopts = {
      title = "Select project or solution",
    },
    actions = {
      ["default"] = function(selected, opts)
        list_secrets(selected[1])
      end,
    },
  })
end

return M
