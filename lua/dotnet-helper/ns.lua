local a = require("dotnet-helper.async")
local fs = require("dotnet-helper.fs")
local utils = require("dotnet-helper.utils")

local M = {}
local H = {}

M.adjust_ns = a.async(function()
  local dir = a.input({ prompt = "Enter directory: ", default = fs.cwd(), completion = "dir" })
  if utils.is_empty(dir) then
    return
  end
  dir = vim.fs.normalize(dir)

  local paths = utils.get_file_options(dir, { "cs" })

  -- Read all files and compute namespaces
  local files = {}
  for _, path in ipairs(paths) do
    local lines = fs.read_lines(path)
    local fixed_text_result = H.get_fixed_lines(lines, path)
    -- ignore if file does not have namespace (from)
    if fixed_text_result.from then
      table.insert(files, {
        path = path,
        lines = fixed_text_result.lines,
        original_lines = lines,
        from = fixed_text_result.from,
        to = fixed_text_result.to,
      })
    end
  end

  -- Build mapping table
  local mappings = {}
  for _, f in ipairs(files) do
    if f.from ~= f.to then
      mappings[f.from] = f.to
    end
  end

  -- Find unused namespaces
  local unused_namespaces = {}
  for from, _ in pairs(mappings) do
    if not vim.iter(files):find(function(x)
      return x.to == from
    end) then
      table.insert(unused_namespaces, from)
    end
  end

  -- Update usings and write
  for _, file in ipairs(files) do
    for from, to in pairs(mappings) do
      if
        vim.iter(file.lines):find(function(x)
            return x:find("using%s+" .. from .. "%s*;")
          end)
          and not vim.iter(file.lines):find(function(x)
            return x:find("using%s+" .. to .. "%s*;")
          end)
        or from == H.get_root_namespace(file.path)
      then
        table.insert(file.lines, 1, "using " .. to .. ";")
      end
    end
    for _, unused_namespace in ipairs(unused_namespaces) do
      for i = #file.lines, 1, -1 do
        local line, count = string.gsub(file.lines[i], "using%s+" .. unused_namespace .. "%s*;", "")
        if count > 0 then
          if line == "" then
            table.remove(file.lines, i)
          else
            file.lines[i] = line
          end
        end
      end
    end
    if not vim.deep_equal(file.lines, file.original_lines) then
      fs.write_lines(file.path, file.lines)
    end
  end
  vim.notify("Done")
end)

---@param lines string[]
---@param filepath string
---@return { updated: boolean, lines: string[], from: string, to: string }
function H.get_fixed_lines(lines, filepath)
  local to = M.compute_namespace(filepath)

  local res = { updated = false, lines = {}, from = nil, to = to }

  for _, line in ipairs(lines) do
    local from = string.match(line, "namespace%s+([^;%s]+)")
    if from and not res.updated then
      res.from = from
      if from ~= to then
        line = string.gsub(line, "namespace%s+[^;%s]+", "namespace " .. to)
        res.updated = true
      end
    end
    table.insert(res.lines, line)
  end
  return res
end

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

H.get_namespace = function(lines)
  for _, line in ipairs(lines) do
    local ns = string.match(line, "^namespace%s+([^;%s]+)")
    if ns then
      return ns
    end
  end
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
