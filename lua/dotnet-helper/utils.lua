local fs = require("dotnet-helper.fs")
local a = require("dotnet-helper.async")

local M = {}

local exclude_dirs = { "obj", "bin", ".git" }

function M.get_projects(include_solution)
  local valid_ext = { "csproj" }
  if include_solution then
    table.insert(valid_ext, "sln")
  end
  return M.get_file_options(fs.cwd(), valid_ext)
end

---Get list of valid project dirs for fzf
function M.get_dir_options(path)
  local result = { path }
  for _, dir_path in ipairs(fs.get_dirs(path)) do
    if not vim.tbl_contains(exclude_dirs, fs.get_file_name(dir_path)) then
      for _, subdir in ipairs(M.get_dir_options(dir_path)) do
        table.insert(result, subdir)
      end
    end
  end
  return result
end

---Get list of valid project files in path
function M.get_file_options(path, valid_ext)
  valid_ext = valid_ext or {}
  local result = {}
  local files = fs.get_files(path)
  for _, file in ipairs(files) do
    local ext = fs.get_ext(file:lower())
    if vim.tbl_isempty(valid_ext) or vim.tbl_contains(valid_ext, ext) then
      table.insert(result, file)
    end
  end
  for _, dir_path in ipairs(fs.get_dirs(path)) do
    if not vim.tbl_contains(exclude_dirs, fs.get_file_name(dir_path)) then
      for _, subresult in ipairs(M.get_file_options(dir_path, valid_ext)) do
        table.insert(result, subresult)
      end
    end
  end
  return result
end

function M.buff_empty(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  return (vim.api.nvim_buf_line_count(buf) <= 1 and #vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == 0)
end

---@param s string?
M.is_empty = function(s)
  return s == nil or s == ""
end

local cached_dotnet_10_value = nil

function M.is_dotnet_10()
  if cached_dotnet_10_value ~= nil then
    return cached_dotnet_10_value
  end

  local result = a.system({ "dotnet", "--version" })

  if not result or not result.stdout then
    error("Failed to retrieve .NET version: no stdout from `dotnet --version`")
  end

  local major = tonumber(result.stdout:match("^%d+"))

  if not major then
    error("Failed to parse .NET version from: " .. tostring(result.stdout))
  end

  cached_dotnet_10_value = major > 10

  return cached_dotnet_10_value
end

--- @param text string  The full multiline text to filter.
--- @param prefix "data"|"error"|"info"  The allowed line prefix.
--- @return string  All matching lines concatenated with "\n".
function M.filter_dotnet_output(text, prefix)
  local out = {}
  for line in text:gmatch("[^\r\n]+") do
    local data = line:match("^" .. prefix .. ":%s*(.*)$")
    if data then
      table.insert(out, data)
    end
  end
  return table.concat(out, "\n")
end

---@return string|nil
M.prompt_project = function(prompt, last)
  local projects = M.get_projects(false)
  if #projects == 0 then
    vim.notify("No projects found in this workspace.", vim.log.levels.WARN)
  elseif #projects == 1 then
    return projects[1]
  else
    if last ~= nil then
      projects = vim.tbl_filter(function(x)
        return x ~= last
      end, projects)
      table.insert(projects, 1, last)
    end
    return a.select(projects, {
      prompt = prompt,
      format_item = function(item)
        local rel_path = fs.relative_path(item)
        if last == item then
          return rel_path .. " (Last selected)"
        end
        return rel_path
      end,
    })
  end
end

return M
