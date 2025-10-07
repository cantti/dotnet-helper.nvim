local utils = require("dotnet-helper.utils")

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
      vim.schedule(function()
        if utils.cur_buff_empty() then
          require("dotnet-helper.templates").insert_class({ block_ns = M.opts.autocommands.use_block_ns })
        end
      end)
    end,
  })
end

local cs_subcommands = {
  secrets = {
    impl = function(args)
      if vim.tbl_contains(args, "--list") then
        require("dotnet-helper").secrets_list()
      else
        require("dotnet-helper").secrets_edit()
      end
    end,
    complete = function(subcmd_arg_lead)
      local args = {
        "--list",
      }
      return vim
        .iter(args)
        :filter(function(install_arg)
          return install_arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
    end,
  },
  ns = {
    impl = function(args)
      if vim.tbl_contains(args, "--dir") then
        require("dotnet-helper").fix_ns_buf()
      else
        require("dotnet-helper").fix_ns_dir()
      end
    end,
    complete = function(subcmd_arg_lead)
      local args = {
        "--dir",
      }
      return vim
        .iter(args)
        :filter(function(install_arg)
          return install_arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
    end,
  },
  nuget = {
    impl = function(args)
      require("dotnet-helper").nuget_search()
    end,
  },
}

---@param opts table
local function cs_command(opts)
  local fargs = opts.fargs
  local subcommand_key = fargs[1]
  -- Get the subcommand's arguments, if any
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local subcommand = cs_subcommands[subcommand_key]
  if not subcommand then
    vim.notify("Dotnet: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)
    return
  end
  -- Invoke the subcommand
  subcommand.impl(args, opts)
end

-- inspired by https://github.com/lumen-oss/nvim-best-practices
function H.add_usercommands()
  vim.api.nvim_create_user_command("Dotnet", cs_command, {
    nargs = "+",
    desc = "My awesome command with subcommand completions",
    complete = function(arg_lead, cmdline, _)
      -- Get the subcommand.
      local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*Dotnet[!]*%s(%S+)%s(.*)$")
      if subcmd_key and subcmd_arg_lead and cs_subcommands[subcmd_key] and cs_subcommands[subcmd_key].complete then
        -- The subcommand has completions. Return them.
        return cs_subcommands[subcmd_key].complete(subcmd_arg_lead)
      end
      -- Check if cmdline is a subcommand
      if cmdline:match("^['<,'>]*Dotnet[!]*%s+%w*$") then
        -- Filter subcommands that match
        local subcommand_keys = vim.tbl_keys(cs_subcommands)
        return vim
          .iter(subcommand_keys)
          :filter(function(key)
            return key:find(arg_lead) ~= nil
          end)
          :totable()
      end
    end,
    bang = false,
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

function M.secrets_list()
  require("dotnet-helper.secrets").list()
end

function M.secrets_edit()
  require("dotnet-helper.secrets").edit()
end

function M.nuget_search()
  require("dotnet-helper.nuget").search()
end

function M.templates()
  require("dotnet-helper.template_chooser").show()
end

function M.templates_class()
  require("dotnet-helper.templates").class()
end

function M.templates_api_controller()
  require("dotnet-helper.templates").api_controller()
end

function M.templates_method()
  require("dotnet-helper.templates").method()
end

function M.fix_ns_buf()
  require("dotnet-helper.fix_ns").fix_ns_buf()
end

function M.fix_ns_dir()
  require("dotnet-helper.fix_ns").fix_ns_dir()
end

return M
