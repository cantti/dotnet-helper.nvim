local M = {}

local templates = require("cshelper.templates")
local command_chooser = require("cshelper.command_chooser")
local build = require("cshelper.build")
local secrets = require("cshelper.secrets")
local run = require("cshelper.run")

local csh_subcommands = {
  commands = {
    impl = function(args, opts)
      command_chooser.show()
    end,
  },
  class = {
    impl = function(args, opts)
      templates.class({ blockns = vim.tbl_contains(args, "blockns") })
    end,
    complete = function(subcmd_arg_lead)
      local install_args = {
        "blockns",
      }
      return vim
        .iter(install_args)
        :filter(function(install_arg)
          return install_arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
    end,
  },
  apicontroller = {
    impl = function(args, opts)
      templates.apicontroller({ blockns = vim.tbl_contains(args, "blockns") })
    end,
    complete = function(subcmd_arg_lead)
      -- Simplified example
      local install_args = {
        "blockns",
      }
      return vim
        .iter(install_args)
        :filter(function(install_arg)
          -- If the user has typed `:Rocks install ne`,
          -- this will match 'neorg'
          return install_arg:find(subcmd_arg_lead) ~= nil
        end)
        :totable()
    end,
    -- ...
  },
  fixns = {
    impl = function(args, opts)
      require("cshelper.fix_ns").fix_ns_document()
    end,
  },
  build = {
    impl = function(args, opts)
      build.execute()
    end,
  },
  run = {
    impl = function(args, opts)
      run.execute()
    end,
  },
  secretslist = {
    impl = function(args, opts)
      secrets.list()
    end,
  },
  secretsedit = {
    impl = function(args, opts)
      secrets.edit()
    end,
  },
}

-- main command :Csh
local function csh_cmd(opts)
  local fargs = opts.fargs
  if vim.tbl_isempty(fargs) then
    command_chooser.show()
    return
  end
  local subcommand_key = fargs[1]
  -- Get the subcommand's arguments, if any
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local subcommand = csh_subcommands[subcommand_key]
  if not subcommand then
    vim.notify("Csh: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)
    return
  end
  -- Invoke the subcommand
  subcommand.impl(args, opts)
end

function M.setup()
  vim.api.nvim_create_user_command("Csh", csh_cmd, {
    nargs = "*",
    desc = "",
    complete = function(arg_lead, cmdline, _)
      -- Get the subcommand.
      local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*Csh[!]*%s(%S+)%s(.*)$")
      if subcmd_key and subcmd_arg_lead and csh_subcommands[subcmd_key] and csh_subcommands[subcmd_key].complete then
        -- The subcommand has completions. Return them.
        return csh_subcommands[subcmd_key].complete(subcmd_arg_lead)
      end
      -- Check if cmdline is a subcommand
      if cmdline:match("^['<,'>]*Csh[!]*%s+%w*$") then
        -- Filter subcommands that match
        local subcommand_keys = vim.tbl_keys(csh_subcommands)
        return vim
          .iter(subcommand_keys)
          :filter(function(key)
            return key:find(arg_lead) ~= nil
          end)
          :totable()
      end
    end,
    bang = true, -- If you want to support ! modifiers
  })
end

return M
