local M = {}

local uv = vim.uv or vim.loop

function M.current_file_path()
  return vim.fn.expand("%:p")
end

function M.remove_trailing_slah(path)
  return string.gsub(path, "/+$", "")
end

function M.get_parent_path(path)
  return vim.fn.fnamemodify(path, ":h")
end

function M.get_file_name(path)
  return vim.fn.fnamemodify(path, ":t")
end

function M.get_file_name_without_ext(path)
  return vim.fn.fnamemodify(path, ":t:r")
end

function M.get_ext(path)
  return vim.fn.fnamemodify(path, ":e")
end

function M.join_paths(paths, normalize)
  if normalize == nil then
    normalize = true
  end
  local path = table.concat(paths, "/")
  if normalize then
    path = vim.fs.normalize(path)
  end
  return path
end

function M.abs_path(path)
  return vim.fn.fnamemodify(path, ":p")
  -- old version
  -- if not M.is_absolute(path) then
  --   -- fnamemodify gives unpredictable results if file does not exist
  --   return M.join_paths({ vim.fn.getcwd(), path })
  -- else
  --   return path
  -- end
end

function M.relative_path(path)
  return vim.fn.fnamemodify(path, ":.")
end

M.is_windows = uv.os_uname().version:match("Windows")

function M.is_absolute(path)
  if M.is_windows then
    return path:match("^%a:/")
  else
    return vim.startswith(path, "/")
  end
end

function M.normalize(path)
  return vim.fs.normalize(path)
end

function M.cwd()
  return vim.fn.getcwd()
end

function M.get_files(path)
  local files = {}
  local handle = vim.loop.fs_scandir(path)
  if handle then
    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end
      if type == "file" then
        table.insert(files, M.join_paths({ path, name }))
      end
    end
  end
  return files
end

function M.get_dirs(path)
  local dirs = {}
  local handle = vim.loop.fs_scandir(path)
  if handle then
    while true do
      local name, type = vim.loop.fs_scandir_next(handle)
      if not name then
        break
      end
      if type == "directory" then
        table.insert(dirs, M.join_paths({ path, name }))
      end
    end
  end
  return dirs
end

function M.file_exists(path)
  local f = io.open(path, "r")
  if f then
    f:close()
    return true
  else
    return false
  end
end

function M.read(filepath)
  local file = io.open(filepath, "r") -- Open file in read mode
  if not file then
    print("Error: Unable to open file " .. filepath)
    return nil
  end

  local lines = {} -- Table to store lines
  for line in file:lines() do
    table.insert(lines, line)
  end

  file:close() -- Close the file
  return lines -- Return table with file content
end

return M
