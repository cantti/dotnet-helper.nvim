local utils = require("cshelper.utils")
local fs = require("cshelper.fs")

local M = {}
local H = {}

---@class NugetPackage
---@field id string
---@field version string
---@field downloads integer|nil
---@field source string|nil
---@field description string|nil

local function run(cmd, on_done)
  vim.system(
    cmd,
    { text = true },
    vim.schedule_wrap(function(out)
      on_done(out)
    end)
  )
end

--- Prompt user to pick a package from a list.
---@param packages NugetPackage[]
---@param cb fun(pkg: NugetPackage)
function H.prompt_package(packages, cb)
  if not packages or #packages == 0 then
    vim.notify("No packages found for that query.", vim.log.levels.INFO)
    return
  end
  vim.ui.select(packages, {
    prompt = "Choose package:",
    ---@param item NugetPackage
    format_item = function(item)
      local desc = tostring(item.description or ""):match("^[^\r\n]*") or ""
      return string.format("%s %s (%s) - %s", item.id, item.version or "?", item.source or "nuget", desc)
    end,
  }, function(package)
    if not package then
      return
    end
    cb(package)
  end)
end

--- Prompt for a version (defaulting to package.latest).
---@param package NugetPackage
---@param cb fun(s: string)
function H.prompt_version(package, cb)
  local default = package and package.version or ""
  vim.ui.input({ prompt = "Version: ", default = default }, function(version)
    if version == nil or version == "" then
      return
    end
    cb(version)
  end)
end

--- Prompt to choose a project (or auto-pick if only one).
---@param cb fun(project: string)
function H.prompt_project(cb)
  local projects = utils.get_projects(false) or {}
  if #projects == 0 then
    vim.notify("No projects found in this workspace.", vim.log.levels.WARN)
  elseif #projects == 1 then
    cb(projects[1])
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
      cb(project)
    end)
  end
end

--- Run `dotnet add package`.
---@param package NugetPackage
---@param version string
---@param project string
function H.add_package(package, version, project)
  local args = { "dotnet", "add", project, "package", package.id, "--version", version }
  run(args, function(out)
    if out.code == 0 then
      vim.cmd("edit " .. project)
      vim.notify(
        string.format("Added %s %s to %s", package.id, version, fs.relative_path(project)),
        vim.log.levels.INFO
      )
    else
      local msg = (#out.stderr > 0 and out.stderr) or "Error adding package"
      vim.notify(msg, vim.log.levels.ERROR)
    end
  end)
end

--- Search packages via dotnet and return a flat list.
---@param input string
---@param cb fun(pkgs: NugetPackage[])
function H.fetch_packages(input, cb)
  run(
    { "dotnet", "package", "search", input, "--format", "json", "--take", "20", "--verbosity", "detailed" },
    function(out)
      if out.code ~= 0 then
        vim.notify((#out.stderr > 0 and out.stderr) or "Search failed", vim.log.levels.ERROR)
        cb({})
        return
      end
      local ok, result = pcall(vim.json.decode, out.stdout)
      if not ok or not result or not result.searchResult then
        vim.notify("Could not parse search results.", vim.log.levels.ERROR)
        cb({})
        return
      end
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
      cb(packages)
    end
  )
end

--- Prompt for a search query.
---@param cb fun(s: string)
function H.prompt_search(cb)
  vim.ui.input({ prompt = "Query: " }, function(s)
    if s == nil or s == "" then
      return
    end
    cb(s)
  end)
end

function M.search()
  H.prompt_search(function(input)
    H.fetch_packages(input, function(packages)
      H.prompt_package(packages, function(package)
        H.prompt_version(package, function(version)
          H.prompt_project(function(project)
            H.add_package(package, version, project)
          end)
        end)
      end)
    end)
  end)
end

return M
