local utils = require("cshelper.utils")

local M = {}

local function readAll(file)
  local f = assert(io.open(file, "rb"))
  local content = f:read("*all")
  f:close()
  return content
end

local function write_to_file(path, content)
  local file = io.open(path, "w") -- Open the file in write mode
  if not file then
    return false, "Error: Could not open file for writing."
  end

  file:write(content) -- Write the content to the file
  file:close() -- Close the file
  return true, "File written successfully."
end

function M.execute()
  local dir = vim.fn.input("Enter directory path: ", ".", "dir")
  local files = utils.get_file_options(dir, { "cs" })
  local updated_files = {}
  local transitions = {}

  -- update namespace in files
  for _, file_path in ipairs(files) do
    local content = readAll(file_path)
    local old_ns = string.match(content, "namespace%s+([^;%s]+)")
    local new_ns = utils.get_namespace_for_file(file_path)

    if old_ns and old_ns ~= new_ns then
      -- namespace can end on ; or space (new line)
      content = string.gsub(content, "namespace%s+[^;%s]+", "namespace " .. new_ns)
      table.insert(updated_files, file_path)
      transitions[old_ns] = new_ns
      write_to_file(file_path, content)
    end
  end

  vim.print(transitions)

  -- update usings
  local all_files = utils.get_file_options(".", { "cs" })
  for _, file_path in ipairs(all_files) do
    local content = readAll(file_path)
    local is_updated = false
    for old_ns, new_ns in pairs(transitions) do
      local count
      content, count = string.gsub(content, "using%s+" .. old_ns .. ";", "using " .. new_ns .. ";")
      is_updated = is_updated or count > 0
    end
    if is_updated then
      write_to_file(file_path, content)
    end
  end
  -- update buffers
  vim.cmd("bufdo checktime")

  vim.print("Updated files count: " .. vim.tbl_count(updated_files))
end

return M
