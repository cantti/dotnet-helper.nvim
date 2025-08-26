local utils = require("cshelper.utils")
local fs = require("cshelper.fs")

local Nuget = {}
Nuget.__index = Nuget

function Nuget:new()
  local obj = setmetatable({}, Nuget)
  obj.packages = nil
  obj.package = nil
  obj.project = nil
  obj.version = nil
  return obj
end

function Nuget:_prompt_package()
  vim.ui.select(self.packages, {
    format_item = function(item)
      return string.format("%s %s (%s)", item.id, item.version, item.source)
    end,
  }, function(package)
    self.package = package
    self:_prompt_version()
  end)
end

function Nuget:_prompt_version()
  vim.ui.input({ prompt = "Version: ", default = self.package.version }, function(version)
    self.version = version
    self:_prompt_project()
  end)
end

function Nuget:_prompt_project()
  local projects = utils.get_projects(false)
  if vim.tbl_count(projects) == 1 then
    self.project = projects[1]
    self:_add_package()
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
      self.project = project
      self:_add_package()
    end)
  end
end

function Nuget:_add_package()
  local args = { "dotnet", "add", self.project, "package", self.package.id, "--version", self.version }
  vim.system(
    args,
    vim.schedule_wrap(function(output)
      if output.code == 0 then
        vim.cmd("edit " .. self.project)
      else
        vim.notify("Error adding package", vim.log.levels.INFO)
      end
    end)
  )
end

function Nuget:search()
  vim.ui.input({ prompt = "Query: " }, function(input)
    vim.system(
      { "dotnet", "package", "search", input, "--format", "json", "--take", "100" },
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
            })
          end
        end
        self.packages = packages
        self:_prompt_package()
      end)
    )
  end)
end

return Nuget
