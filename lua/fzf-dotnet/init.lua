local M = {}

local item_creation = require("fzf-dotnet.item_creation")
local command_chooser = require("fzf-dotnet.command_chooser")
local build = require("fzf-dotnet.build")
local secrets = require("fzf-dotnet.secrets")
local run = require("fzf-dotnet.run")

local fzfdotnet_subcommands = {
  commands = {
    impl = function(args, opts)
      command_chooser.show()
    end,
  },
  writeclass = {
    impl = function(args, opts)
      item_creation.write_class({ blockns = vim.tbl_contains(args, "blockns") })
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
  build = {
    impl = function(args, opts)
      build.build()
    end,
  },
  buildproject = {
    impl = function(args, opts)
      build.build_project_or_solution()
    end,
  },
  runproject = {
    impl = function(args, opts)
      run.run_project()
    end,
  },
  secretslist = {
    impl = function(args, opts)
      secrets.list_secrets()
    end,
  },
  secretsedit = {
    impl = function(args, opts)
      secrets.edit_secrets()
    end,
  },
}

-- main command :Fzfdotnet
local function fzf_dotnet_cmd(opts)
  local fargs = opts.fargs
  if vim.tbl_isempty(fargs) then
    command_chooser.show()
    return
  end
  local subcommand_key = fargs[1]
  -- Get the subcommand's arguments, if any
  local args = #fargs > 1 and vim.list_slice(fargs, 2, #fargs) or {}
  local subcommand = fzfdotnet_subcommands[subcommand_key]
  if not subcommand then
    vim.notify("Fzfdotnet: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)
    return
  end
  -- Invoke the subcommand
  subcommand.impl(args, opts)
end

function M.setup()
  vim.api.nvim_create_user_command("Csw", fzf_dotnet_cmd, {
    nargs = "*",
    desc = "",
    complete = function(arg_lead, cmdline, _)
      -- Get the subcommand.
      local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*Fzfdotnet[!]*%s(%S+)%s(.*)$")
      if
        subcmd_key
        and subcmd_arg_lead
        and fzfdotnet_subcommands[subcmd_key]
        and fzfdotnet_subcommands[subcmd_key].complete
      then
        -- The subcommand has completions. Return them.
        return fzfdotnet_subcommands[subcmd_key].complete(subcmd_arg_lead)
      end
      -- Check if cmdline is a subcommand
      if cmdline:match("^['<,'>]*Fzfdotnet[!]*%s+%w*$") then
        -- Filter subcommands that match
        local subcommand_keys = vim.tbl_keys(fzfdotnet_subcommands)
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
