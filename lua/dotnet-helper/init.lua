local utils = require("dotnet-helper.utils")
local fs = require("dotnet-helper.fs")

local H = {}

---@class DotnetHelperModule
---@field opts DotnetHelperOpts|nil
local M = {}

function H.add_autocommands()
  vim.api.nvim_create_autocmd("BufWinEnter", {
    desc = "Insert C# class when entering an empty C# file",
    group = vim.api.nvim_create_augroup("dotnet-helper", { clear = true }),
    pattern = "*.cs",
    callback = function()
      -- capture current buffer, or Snacks.picker gives strange results
      local buf = vim.api.nvim_get_current_buf()

      vim.schedule(function()
        if not utils.buff_empty(buf) then
          return
        end
        local fname = fs.get_file_name(vim.api.nvim_buf_get_name(buf))
        if fname:match("^I%u") then
          require("dotnet-helper.templates").interface({
            block_ns = M.opts.autocommands.use_block_ns,
            buf = buf,
          })
        else
          require("dotnet-helper.templates").class({ block_ns = M.opts.autocommands.use_block_ns, buf = buf })
        end
      end)
    end,
  })
end

function H.add_usercommands()
  vim.api.nvim_create_user_command("DotnetSecrets", M.secrets, {
    nargs = 0,
    desc = "Edit user secrets file",
  })

  vim.api.nvim_create_user_command("DotnetNuget", M.nuget_search, {
    nargs = 0,
    desc = "Search NuGet packages",
  })

  vim.api.nvim_create_user_command("DotnetEf", M.ef, {
    nargs = 0,
    desc = "Run EF migrations actions",
  })

  vim.api.nvim_create_user_command("DotnetTest", M.test, {
    nargs = 0,
    desc = "Run dotnet test for project",
  })
end

---@class DotnetHelperAutocmdOpts
---@field enabled boolean
---@field use_block_ns boolean

---@class DotnetHelperUsercmdOpts
---@field enabled boolean
---@field use_block_ns boolean

---@class DotnetHelperOpts
---@field autocommands DotnetHelperAutocmdOpts
---@field usercommands DotnetHelperUsercmdOpts
local defaults = {
  autocommands = {
    enabled = true,
    use_block_ns = false,
  },
  usercommands = {
    enabled = true,
    use_block_ns = false,
  },
}

function M.setup(opts)
  opts = opts or {}
  M.opts = vim.tbl_deep_extend("force", defaults, opts)
  if M.opts.autocommands.enabled then
    H.add_autocommands()
  end
  if M.opts.usercommands.enabled then
    H.add_usercommands()
  end
end

function M.secrets()
  require("dotnet-helper.secrets").secrets()
end

function M.nuget_search()
  require("dotnet-helper.nuget").search()
end

function M.templates_api_controller()
  require("dotnet-helper.templates").api_controller()
end

function M.templates_method()
  require("dotnet-helper.templates").method()
end

function M.ef()
  require("dotnet-helper.ef").ef()
end

function M.test()
  require("dotnet-helper.test").test()
end

function M.adjust_ns()
  require("dotnet-helper.ns").adjust_ns()
end

return M
