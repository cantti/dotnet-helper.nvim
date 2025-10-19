local utils = require("dotnet-helper.utils")
local fs = require("dotnet-helper.fs")
local a = require("dotnet-helper.async")

local M = {}
local H = {}

H.project = nil

---@class NugetPackage
---@field id string
---@field version string
---@field downloads integer|nil
---@field source string|nil
---@field description string|nil

--- Prompt user to pick a package from a list.
---@param packages NugetPackage[]
---@return NugetPackage|nil
H.prompt_package = function(packages)
  return a.select(packages, {
    prompt = "Choose package:",
    ---@param item NugetPackage
    format_item = function(item)
      local desc = tostring(item.description or ""):match("^[^\r\n]*") or ""
      return string.format("%s %s (%s) - %s", item.id, item.version or "?", item.source or "nuget", desc)
    end,
  })
end

---@param package NugetPackage
---@param version string
---@param project string
H.add_package = function(package, version, project)
  local args
  if utils.is_dotnet_10() then
    args = { "dotnet", "package", "add", package.id, "--version", version, "--project", project }
  else
    args = { "dotnet", "add", project, "package", package.id, "--version", version }
  end
  local output = a.system(args)
  if output.code == 0 then
    vim.cmd("edit " .. project)
    vim.notify(string.format("Added %s %s to %s", package.id, version, fs.relative_path(project)), vim.log.levels.INFO)
  else
    local msg = (#output.stderr > 0 and output.stderr) or "Error adding package"
    vim.notify(msg, vim.log.levels.ERROR)
  end
end
---
---@param input string
---@return NugetPackage[] result
H.fetch_packages = function(input)
  local output = a.system({
    "dotnet",
    "package",
    "search",
    input,
    "--format",
    "json",
    "--take",
    "20",
    "--verbosity",
    "detailed",
  })
  if output.code ~= 0 then
    local err = (output and output.stderr ~= "" and output.stderr) or "dotnet package search failed"
    error(err)
  end
  local result = vim.json.decode(output.stdout)
  local packages = {}
  for _, searchResult in ipairs(result.searchResult) do
    for _, package in ipairs(searchResult.packages or {}) do
      table.insert(packages, {
        id = package.id,
        version = package.latestVersion,
        downloads = package.totalDownloads,
        source = searchResult.sourceName,
        description = package.description,
      })
    end
  end
  return packages
end

M.search = a.async(function()
  local input = a.input({ prompt = "Query: " })
  if utils.is_empty(input) then
    return
  end
  local packages = H.fetch_packages(input)
  if #packages == 0 then
    vim.notify("No packages found for that query.", vim.log.levels.INFO)
    return
  end
  local package = H.prompt_package(packages)
  if not package then
    return
  end
  local version = a.input({ prompt = "Version: ", default = package.version })
  if utils.is_empty(version) then
    return
  end
  H.project = utils.prompt_project("Choose project: ", H.project)
  if not H.project then
    return
  end
  H.add_package(package, version, H.project)
end)

return M
