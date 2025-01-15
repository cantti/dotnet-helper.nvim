local M = {}

function M.remove_trailing_slah(path)
  return string.gsub(path, "/+$", "")
end

-- get parent dir full path
function M.get_directory_path(path)
  -- if no slashes return ""
  if not string.match(path, "/") then
    return ""
  end
  -- if ends on slash return ""
  if string.match(path, "/$") then
    return ""
  end
  -- if in / return /
  if string.match(path, "^/[^/]+$") then
    return "/"
  end
  -- return everthing before /
  return string.match(path, "^(.+)/[^/]+$")
end

function M.get_file_name(path)
  -- if no slashes, return path
  if not string.match(path, "/") then
    return path
  end
  return string.match(path, "/([^/]+)$")
end

function M.get_ext(path)
  return string.match(path, "%.([^%.]+)$") or ""
end

function M.join_paths(...)
  local final_path = ""
  for i, element in ipairs({ ... }) do
    -- replace slashes
    element = string.gsub(element, "\\", "/")

    -- remove ./ if not the first element
    if i > 1 then
      element = string.gsub(element, "^%./", "")
    end

    -- remove trailing slash
    element = string.gsub(element, "/$", "")

    if element ~= "" then
      final_path = final_path .. "/" .. element
    end
  end
  final_path = string.sub(final_path, 2)
  return final_path
end

function M.get_files(dir)
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

function M.get_dirs(dir_path)
  local dirs = {}
  local handle = vim.loop.fs_scandir(dir_path)
  if handle then
    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end
      if type == "directory" then
        table.insert(dirs, M.join_paths(dir_path, name))
      end
    end
  end
  return dirs
end

return M
