local utils = require("cshelper.utils")
local fs = require("cshelper.fs")

local M = {}

local function on_select(package)
  local targets = utils.get_projects(false)
  if vim.tbl_count(targets) == 1 then
  else
    vim.ui.select(targets, {
      prompt = "Choose project:",
      format_item = function(item)
        return fs.relative_path(item)
      end,
    }, function(project)
      if not project then
        return
      end
      local args = { "dotnet", "add", project, "package", package.id }
      dd(args)
      local output = vim.system(args):wait()
      if output.code == 0 then
        vim.notify("Package added", vim.log.levels.INFO)
      end
    end)
  end
end

local function search(input)
  local output = vim.system({ "dotnet", "package", "search", input, "--format", "json" }):wait()
  local result = vim.json.decode(output.stdout)
  local packages = result.searchResult[1].packages
  local max_id = 0
  for _, item in ipairs(packages) do
    max_id = math.max(max_id, #item.id)
  end
  vim.ui.select(result.searchResult[1].packages, {
    format_item = function(item)
      return string.format(
        "%-" .. max_id .. "s | Version: %-12s | Downloads: %-10s",
        item.id,
        item.latestVersion,
        item.totalDownloads
      )
    end,
  }, on_select)
end

function M.search()
  vim.ui.input({ prompt = "Query:" }, search)
end

return M
