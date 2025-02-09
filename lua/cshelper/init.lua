local M = {}

function M.setup()
  vim.api.nvim_create_user_command("Csh", require("cshelper.command_chooser").show, {})
end

function M.fix_ns(opts)
  require("cshelper.fix_ns").fix_ns(opts)
end

return M
