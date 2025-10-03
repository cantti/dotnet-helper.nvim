local utils = require("cshelper.utils")

local H = {}

---@class CshelperModule
---@field opts CshelperOpts|nil
local M = {}

function H.add_autocommands()
  vim.api.nvim_create_autocmd("BufWinEnter", {
    desc = "Insert C# class when entering an empty C# file",
    group = vim.api.nvim_create_augroup("Cshelper", { clear = true }),
    pattern = "*.cs",
    callback = function()
      vim.schedule(function()
        if utils.cur_buff_empty() then
          require("cshelper.templates").insert_class({ block_ns = M.opts.autocommands.use_block_ns })
        end
      end)
    end,
  })
end

local cs_subcommands = {
  secrets = {
    impl = function(args)
      if vim.tbl_contains(args, "--list") then
        require("cshelper").secrets_list()
      else
        require("cshelper").secrets_edit()
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
        require("cshelper").fix_ns_buf()
      else
        require("cshelper").fix_ns_dir()
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
    -- ...
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
    vim.notify("Rocks: Unknown command: " .. subcommand_key, vim.log.levels.ERROR)
    return
  end
  -- Invoke the subcommand
  subcommand.impl(args, opts)
end

-- inspired by https://github.com/lumen-oss/nvim-best-practices
function H.add_usercommands()
  vim.api.nvim_create_user_command("Cs", cs_command, {
    nargs = "+",
    desc = "My awesome command with subcommand completions",
    complete = function(arg_lead, cmdline, _)
      -- Get the subcommand.
      local subcmd_key, subcmd_arg_lead = cmdline:match("^['<,'>]*Cs[!]*%s(%S+)%s(.*)$")
      if subcmd_key and subcmd_arg_lead and cs_subcommands[subcmd_key] and cs_subcommands[subcmd_key].complete then
        -- The subcommand has completions. Return them.
        return cs_subcommands[subcmd_key].complete(subcmd_arg_lead)
      end
      -- Check if cmdline is a subcommand
      if cmdline:match("^['<,'>]*Cs[!]*%s+%w*$") then
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

---@class CshelperAutocmdOpts
---@field enabled boolean
---@field use_block_ns boolean

---@class CshelperUsercmdOpts
---@field enabled boolean
---@field use_block_ns boolean

---@class CshelperOpts
---@field autocommands CshelperAutocmdOpts
---@field usercommands CshelperUsercmdOpts
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
  require("cshelper.secrets").list()
end

function M.secrets_edit()
  require("cshelper.secrets").edit()
end

function M.nuget_search()
  require("cshelper.nuget").search()
end

function M.templates()
  require("cshelper.template_chooser").show()
end

function M.templates_class()
  require("cshelper.templates").class()
end

function M.templates_api_controller()
  require("cshelper.templates").api_controller()
end

function M.templates_method()
  require("cshelper.templates").method()
end

function M.fix_ns_buf()
  require("cshelper.fix_ns").fix_ns_buf()
end

function M.fix_ns_dir()
  require("cshelper.fix_ns").fix_ns_dir()
end

return M
