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
      if utils.cur_buff_empty() then
        vim.schedule(function()
          require("cshelper.templates").insert_class({ block_ns = M.opts.autocommands.use_block_ns })
        end)
      end
    end,
  })
end

---@class CshelperAutocmdOpts
---@field enabled boolean
---@field use_block_ns boolean

---@class CshelperOpts
---@field autocommands CshelperAutocmdOpts
local defaults = {
  autocommands = {
    enabled = false,
    use_block_ns = false,
  },
}

function M.setup(opts)
  opts = opts or {}
  M.opts = vim.tbl_deep_extend("force", defaults, opts)
  if M.opts.autocommands.enabled then
    H.add_autocommands()
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
