local M = {}

local fs = require("fzf-dotnet.fs")

local function get_build_targets(path)
  local function get_targets_recursive(dir_path, base)
    local result = {}
    local files = fs.get_files(dir_path)
    for _, file in ipairs(files) do
      local filename = fs.get_file_name(file)
      local ext = fs.get_ext(filename:lower())
      if ext == "csproj" or ext == "sln" then
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

function M.build_project_or_solution()
  local cwd = vim.fn.getcwd()
  local targets = get_build_targets(cwd)

  require("fzf-lua").fzf_exec(targets, {
    winopts = {
      title = "Select project or solution",
    },
    actions = {
      ["default"] = function(selected, opts)
        vim.cmd("! dotnet build " .. selected[1])
      end,
    },
  })
end

function M.build_solution()
  local solution
  local cwd = vim.fn.getcwd()
  for _, target in ipairs(get_build_targets(cwd)) do
    local ext = fs.get_ext(target:lower())
    if ext == "sln" then
      solution = target
      break
    end
  end
  if solution then
    vim.cmd("! dotnet build " .. solution)
  end
end

return M
