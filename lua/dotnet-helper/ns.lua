local fs = require("dotnet-helper.fs")

local M = {}
local H = {}

---@param file_path string
---@return string
function M.compute_namespace(file_path)
  local elements = {}
  local csproj_path
  local curr_path = file_path
  local max_level = 5
  for _ = 1, max_level do
    curr_path = fs.get_parent_path(curr_path)

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
    -- do not go above pwd
    if curr_path == vim.fn.getcwd() then
      break
    end
  end
  if csproj_path then
    local root_namespace = H.get_root_namespace(csproj_path)
    if root_namespace then
      table.insert(elements, 1, root_namespace)
    end
  end
  local namespace
  if vim.tbl_count(elements) > 0 then
    namespace = table.concat(elements, ".")
  end
  return namespace
end

function H.get_root_namespace(path)
  local namespace
  for line in io.lines(path) do
    namespace = string.match(line, "<RootNamespace>([^<>]+)</RootNamespace>")
    if namespace then
      break
    end
  end
  if not namespace then
    namespace = fs.get_file_name_without_ext(path)
  end
  return namespace
end

return M
