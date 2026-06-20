local M = {}

function M.reload_utils_with_mocked_system(system_fn)
  package.loaded["dotnet-helper.utils"] = nil
  package.loaded["dotnet-helper.fs"] = nil
  package.loaded["dotnet-helper.async"] = { system = system_fn }

  _G.vim = {
    uv = {
      os_uname = function()
        return { version = "Darwin" }
      end,
    },
    loop = nil,
  }

  return require("dotnet-helper.utils")
end

return M
