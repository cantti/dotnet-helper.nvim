local utils = require("cshelper.utils")
local fs = require("cshelper.fs")

---@class NugetPackage
---@field id string
---@field version string
---@field downloads integer
---@field source string
---@field description string

---@class Nuget
---@field packages NugetPackage[]|nil
---@field selected_package NugetPackage|nil
---@field selected_project string|nil
---@field selected_version string|nil
local Nuget = {}

Nuget.__index = Nuget

function Nuget:new()
  local obj = setmetatable({}, Nuget)
  obj.packages = nil
  obj.selected_package = nil
  obj.selected_project = nil
  obj.selected_version = nil
  return obj
end

---@package
function Nuget:prompt_package()
  vim.ui.select(self.packages, {
    ---@param item NugetPackage
    format_item = function(item)
      -- take only first line of description
      local description = item.description:match("^[^\r\n]*")
      return string.format("%s %s (%s) - %s", item.id, item.version, item.source, description)
    end,
  }, function(package)
    if not package then
      return
    end
    self.selected_package = package
    self:prompt_version()
  end)
end

---@package
function Nuget:prompt_version()
  vim.ui.input({ prompt = "Version: ", default = self.selected_package.version }, function(version)
    self.selected_version = version
    self:prompt_project()
  end)
end

---@package
function Nuget:prompt_project()
  local projects = utils.get_projects(false)
  if #projects == 1 then
    self.selected_project = projects[1]
    self:add_package()
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
      self.selected_project = project
      self:add_package()
    end)
  end
end

---@package
function Nuget:add_package()
  local args =
    { "dotnet", "add", self.selected_project, "package", self.selected_package.id, "--version", self.selected_version }
  vim.system(
    args,
    vim.schedule_wrap(function(output)
      if output.code == 0 then
        vim.cmd("edit " .. self.selected_project)
      else
        vim.notify("Error adding package", vim.log.levels.INFO)
      end
    end)
  )
end

function Nuget:search()
  vim.ui.input({ prompt = "Query: " }, function(input)
    vim.system(
      { "dotnet", "package", "search", input, "--format", "json", "--take", "20", "--verbosity", "detailed" },
      vim.schedule_wrap(function(output)
        local result = vim.json.decode(output.stdout)
        local packages = {}
        for _, searchResult in ipairs(result.searchResult) do
          for _, package in ipairs(searchResult.packages) do
            table.insert(packages, {
              id = package.id,
              version = package.latestVersion,
              downloads = package.totalDownloads,
              source = searchResult.sourceName,
              description = package.description,
            })
          end
        end
        self.packages = packages
        self:prompt_package()
      end)
    )
  end)
end

return Nuget
