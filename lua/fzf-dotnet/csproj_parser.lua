local M = {}

function M.get_root_namespace(path)
  local namespace
  for line in io.lines(path) do
    namespace = string.match(line, "<RootNamespace>([a-zA-Z_]+)</RootNamespace>")
    if namespace then
      break
    end
  end
  return namespace
end

return M
