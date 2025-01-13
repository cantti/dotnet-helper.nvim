local M = {}
local fs = require("fzf-lua-dotnet.fs")
local csproj_parser = require("fzf-lua-dotnet.csproj_parser")

local function file_exists(filepath)
  local f = io.open(filepath, "r")
  if f then
    f:close()
    return true
  else
    return false
  end
end

local function get_namespace_for_file(file_path)
  local elements = {}
  local csproj_path
  local current_path = file_path
  local max_level = 5
  for i = 1, max_level do
    current_path = fs.get_directory_path(current_path)
    if current_path == "/" then
      break
    end
    local files_in_dir = fs.get_files_in_dir(current_path)
    for _, file in ipairs(files_in_dir) do
      if string.match(file:lower(), ".csproj$") then
        csproj_path = file
        break
      end
    end
    if csproj_path then
      break
    end
    local dir_name = fs.get_file_name(current_path)
    table.insert(elements, 1, dir_name)
  end
  if csproj_path then
    local root_namespace = csproj_parser.get_root_namespace(csproj_path)
    table.insert(elements, 1, root_namespace)
  else
    vim.print("Project not found")
  end
  local namespace = ""
  for _, element in ipairs(elements) do
    namespace = namespace .. "." .. element
  end
  namespace = string.gsub(namespace, "^.", "")
  return namespace
end

local str_to_table = function(inputstr)
  local lines = {}
  for s in inputstr:gmatch("[^\r\n]+") do
    table.insert(lines, s)
  end
  return lines
end

function M.get_new_class_locations(path)
  local function get_all_subdirs(dir_path, base)
    local res = {}
    local dirs = fs.get_dirs(dir_path)
    for _, dir in ipairs(dirs) do
      local dir_name = fs.get_file_name(dir)
      if dir_name ~= "obj" and dir_name ~= "bin" then
        local entry = fs.join_paths(base, dir_name)
        table.insert(res, entry)
        local subdirs = get_all_subdirs(dir, entry)
        for _, subdir in ipairs(subdirs) do
          table.insert(res, subdir)
        end
      end
    end
    return res
  end
  local locations = get_all_subdirs(path, "./")
  table.insert(locations, 1, "./")
  return locations
end

function M.new_class()
  local cwd = vim.fn.getcwd()
  local locations = M.get_new_class_locations(cwd)

  require("fzf-lua").fzf_exec(locations, {
    winopts = {
      title = "Select folder",
    },
    actions = {
      ["default"] = function(selected, opts)
        local location = selected[1]
        local class_name = vim.fn.input("Enter name: ")
        local file_name = class_name .. ".cs"

        local file_path = fs.join_paths(cwd, location, file_name)

        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(buf, file_path)
        vim.api.nvim_buf_set_option(buf, "filetype", "cs")
        vim.api.nvim_set_current_buf(buf)

        local namespace = get_namespace_for_file(file_path)
        if not namespace then
          return
        end

        local lines = {
          "namespace " .. namespace .. ";",
          "",
          "public class " .. class_name,
          "{",
          "}",
        }
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        -- vim.cmd("write")
      end,
    },
  })
end

return M
