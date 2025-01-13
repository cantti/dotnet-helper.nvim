local M = {}

function M.remove_trailing_slah(path)
  return string.gsub(path, "/+$", "")
end

-- get parent dir full path
function M.get_directory_path(path)
  if not string.match(path, "/") then
    return ""
  end
  if string.match(path, "/$") then
    return ""
  end
  return string.match(path, "^(.+)/[^/]+$")
end

-- if ends on slash, return
function M.get_file_name(path)
  -- if no slashes, return path
  if not string.match(path, "/") then
    return path
  end
  return string.match(path, "/([^/]+)$")
end

function M.join_paths(...)
  local final_path = ""
  for _, element in ipairs({ ... }) do
    element = string.gsub(element, "\\", "/")
    element = string.gsub(element, "/$", "")
    final_path = final_path .. "/" .. element
  end
  final_path = string.sub(final_path, 2)
  return final_path
end

function M.get_files_in_dir(dir)
  local files = {}
  local handle = vim.loop.fs_scandir(dir)
  if handle then
    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end
      if type == "file" then
        local full_path = dir .. "/" .. name
        table.insert(files, full_path)
      end
    end
  end
  return files
end

function M.create_file(filename)
  local file = io.open(filename, "w") -- Open in write mode
  if file then
    file:write("") -- Optionally write some content
    file:close()
    print("File created: " .. filename)
  else
    print("Failed to create file: " .. filename)
  end
end

return M
