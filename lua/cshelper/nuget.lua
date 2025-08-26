local utils = require("cshelper.utils")
local fs = require("cshelper.fs")

local M = {}

local H = {}

function M.search()
  vim.ui.input({ prompt = "Query: " }, H.prompt_package)
end

function H.prompt_package(input)
  local function on_exit(output)
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
        return string.format("%s %s (%s)", item.id, item.version, item.source)
      end,
    }, H.prompt_project)
  end
  vim.system({ "dotnet", "package", "search", input, "--format", "json", "--take", "100" }, vim.schedule_wrap(on_exit))
end

function H.prompt_project(package)
  local projects = utils.get_projects(false)
  if vim.tbl_count(projects) == 1 then
    H.prompt_version(projects[1], package)
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
      H.prompt_version(project, package)
    end)
  end
end

function H.prompt_version(project, package)
  vim.ui.input({ prompt = "Version: ", default = package.version }, function(version)
    H.add_package(package, project, version)
  end)
end

function H.add_package(package, project, version)
  local args = { "dotnet", "add", project, "package", package.id, "--version", version }
  local function on_exit(output)
    if output.code == 0 then
      vim.cmd("edit " .. project)
      vim.notify(
        string.format("Package %s added to project %s", package.id, fs.get_file_name(project)),
        vim.log.levels.INFO
      )
    end
  end
  vim.system(args, vim.schedule_wrap(on_exit))
end

return M
