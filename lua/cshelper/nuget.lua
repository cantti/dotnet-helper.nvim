local utils = require("cshelper.utils")
local fs = require("cshelper.fs")

local M = {}

local function on_select_project(project, package)
  local args = { "dotnet", "add", project, "package", package.id }
  local output = vim.system(args):wait()
  if output.code == 0 then
    vim.cmd("edit " .. project)
    vim.notify("Package added", vim.log.levels.INFO)
  end
end

local function on_select_search_result(package)
  local projects = utils.get_projects(false)
  if vim.tbl_count(projects) == 1 then
    on_select_project(projects[1], package)
  else
    vim.ui.select(projects, {
      prompt = "Choose project:",
      format_item = function(item)
        return fs.relative_path(item)
      end,
    }, function(project)
      if not project then
        return
      end
      on_select_project(project, package)
    end)
  end
end

local function search(input)
  local output = vim.system({ "dotnet", "package", "search", input, "--format", "json" }):wait()
  local result = vim.json.decode(output.stdout)
  local packages = {}
  for _, searchResult in ipairs(result.searchResult) do
    for _, package in ipairs(searchResult.packages) do
      table.insert(packages, {
        id = package.id,
        version = package.latestVersion,
        downloads = package.totalDownloads,
        source = searchResult.sourceName,
      })
    end
  end
  local max_id = 0
  for _, item in ipairs(packages) do
    max_id = math.max(max_id, #item.id)
  end
  vim.ui.select(packages, {
    format_item = function(item)
      return string.format(
        "%-" .. max_id .. "s | Version: %-12s | Downloads: %-10s | Source: %s",
        item.id,
        item.version,
        item.downloads,
        item.source
      )
    end,
  }, on_select_search_result)
end

function M.search()
  vim.ui.input({ prompt = "Query:" }, search)
end

return M
