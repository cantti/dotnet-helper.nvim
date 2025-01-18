local fs = require("fzf-dotnet.fs")

local M = {}

function M.get_projects(path, include_solution)
  local function get_targets_recursive(dir_path, base)
    local result = {}
    local files = fs.get_files(dir_path)
    for _, file in ipairs(files) do
      local filename = fs.get_file_name(file)
      local ext = fs.get_ext(filename:lower())
      if ext == "csproj" or (include_solution and ext == "sln") then
        table.insert(result, fs.join_paths(base, filename))
      end
    end
    local dirs = fs.get_dirs(dir_path)
    for _, dir in ipairs(dirs) do
      local dirname = fs.get_file_name(dir)
      local sub_results = get_targets_recursive(dir, fs.join_paths(base, dirname))
      for _, sub_result in ipairs(sub_results) do
        table.insert(result, sub_result)
      end
    end
    return result
  end
  local locations = get_targets_recursive(path, "./")
  return locations
end

function M.get_solution(path)
  local solution
  for _, target in ipairs(M.get_projects(path, true)) do
    local ext = fs.get_ext(target:lower())
    if ext == "sln" then
      solution = target
      break
    end
  end
  return solution
end

function M.get_root_namespace(path)
  local namespace
  for line in io.lines(path) do
    namespace = string.match(line, "<RootNamespace>([^<>]+)</RootNamespace>")
    if namespace then
      break
    end
  end
  return namespace
end

return M
