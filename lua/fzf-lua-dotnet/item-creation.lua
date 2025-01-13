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

  -- remove file name from path
  file_path = fs.get_directory_path(file_path)
  local csproj_path = ""

  local function traverse(path)
    local files_in_dir = fs.get_files_in_dir(path)
    for _, file in ipairs(files_in_dir) do
      if string.find(file, "csproj") then
        csproj_path = file
        return
      end
    end
    local dir_name = fs.get_file_name(path)
    table.insert(elements, 1, dir_name)
    traverse(fs.get_directory_path(path))
  end

  traverse(file_path)

  local root_namespace = csproj_parser.get_root_namespace(csproj_path)

  table.insert(elements, 1, root_namespace)

  local namespace = ""

  for _, element in ipairs(elements) do
    namespace = namespace .. "." .. element
  end

  namespace = string.gsub(namespace, "^.", "")

  return namespace
end

function M.new_class()
  require("fzf-lua").fzf_exec("fd --color=never --type d --exclude bin --exclude obj", {
    winopts = {
      title = "Select folder",
    },
    actions = {
      ["default"] = function(selected, opts)
        local directory = selected[1]
        local class_name = vim.fn.input("Enter name: ")
        local file_name = class_name .. ".cs"

        -- full abs path
        local file_path = fs.join_paths(vim.fn.getcwd(), directory, file_name)

        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(buf, file_path)
        vim.api.nvim_buf_set_option(buf, "filetype", "cs")
        vim.api.nvim_set_current_buf(buf)

        local namespace = get_namespace_for_file(file_path)
        local lines = {
          "namespace " .. namespace .. ";",
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
