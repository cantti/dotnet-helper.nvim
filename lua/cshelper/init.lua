local M = {}

function M.setup()
  vim.api.nvim_create_user_command("Csh", require("cshelper.command_chooser").show, {})
end

function M.commands()
  require("cshelper.command_chooser").show()
end

function M.fix_ns(opts)
  require("cshelper.fix_ns").fix_ns(opts)
end

function M.new_class(opts)
  require("cshelper.templates").class(opts)
end

function M.new_api_controller(opts)
  require("cshelper.templates").api_controller(opts)
end

function M.secrets_list()
  require("cshelper.secrets").list()
end

function M.secrets_edit()
  require("cshelper.secrets").edit()
end

return M
