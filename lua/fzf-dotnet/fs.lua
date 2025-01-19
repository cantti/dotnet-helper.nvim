local M = {}

function M.remove_trailing_slah(path)
  return string.gsub(path, "/+$", "")
end

function M.get_parent_path(path)
  return vim.fn.fnamemodify(path, ":h")
end

function M.get_file_name(path)
  return vim.fn.fnamemodify(path, ":t")
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
  -- fnamemodify gives unpredictable results if file does not exist
  return M.join_paths({ vim.fn.getcwd(), path })
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

return M
