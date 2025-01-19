local fs = require("fzf-dotnet.fs")

local M = {}

function M.get_projects(include_solution)
  local valid_ext = { "csproj" }
  if include_solution then
    table.insert(valid_ext, "sln")
  end
  return M.get_files(vim.fn.getcwd(), valid_ext)
end

function M.get_solution()
  local solution
  for _, target in ipairs(M.get_projects(true)) do
    local ext = fs.get_ext(target:lower())
    if ext == "sln" then
      solution = target
      break
    end
  end
  return solution
end

function M.get_namespace_for_file(file_path)
  local elements = {}
  local csproj_path
  local curr_path = file_path
  local max_level = 5
  for i = 1, max_level do
    curr_path = fs.get_directory_path(curr_path)

    for _, file in ipairs(fs.get_files(curr_path)) do
      if fs.get_ext(file:lower()) == "csproj" then
        csproj_path = file
        break
      end
    end

    if csproj_path then
      break
    end

    -- insert dir name as element of namespace
    table.insert(elements, 1, fs.get_file_name(curr_path))

    -- do not go above root and pwd
    if curr_path == "/" or curr_path == vim.fn.getcwd() then
      break
    end
  end
  if csproj_path then
    local root_namespace = M.get_root_namespace(csproj_path)
    table.insert(elements, 1, root_namespace)
  end
  local namespace = ""
  for _, element in ipairs(elements) do
    namespace = namespace .. "." .. element
  end
  namespace = string.gsub(namespace, "^.", "")
  return namespace
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

function M.get_dirs()
  local function get_dirs_recursive(dir_path, base)
    local res = {}
    local dirs = fs.get_dirs(dir_path)
    for _, dir in ipairs(dirs) do
      local dir_name = fs.get_file_name(dir)
      if dir_name ~= "obj" and dir_name ~= "bin" and dir_name ~= ".git" then
        local entry = fs.join_paths(base, dir_name)
        table.insert(res, entry)
        local subdirs = get_dirs_recursive(dir, entry)
        for _, subdir in ipairs(subdirs) do
          table.insert(res, subdir)
        end
      end
    end
    return res
  end
  local locations = get_dirs_recursive(vim.fn.getcwd(), "./")
  table.insert(locations, 1, "./")
  return locations
end

function M.get_files(path, valid_ext)
  valid_ext = valid_ext or {}
  local function get_files_rec(dir_path, base)
    local result = {}
    local files = fs.get_files(dir_path)
    for _, file in ipairs(files) do
      local filename = fs.get_file_name(file)
      local ext = fs.get_ext(filename:lower())
      if vim.tbl_isempty(valid_ext) or vim.tbl_contains(valid_ext, ext) then
        table.insert(result, fs.join_paths(base, filename))
      end
    end
    local dirs = fs.get_dirs(dir_path)
    for _, dir in ipairs(dirs) do
      local dir_name = fs.get_file_name(dir)
      if dir_name ~= "obj" and dir_name ~= "bin" and dir_name ~= ".git" then
        local dirname = fs.get_file_name(dir)
        local sub_results = get_files_rec(dir, fs.join_paths(base, dirname))
        for _, sub_result in ipairs(sub_results) do
          table.insert(result, sub_result)
        end
      end
    end
    return result
  end
  local locations = get_files_rec(path, "./")
  return locations
end

return M
