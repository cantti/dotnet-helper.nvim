local M = {}

function M.setup() end

function M.commands()
  require("cshelper.command_chooser").show()
end

function M.template_commands()
  require("cshelper.command_chooser").show_new()
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

function M.new_property(opts)
  require("cshelper.templates").property(opts)
end

function M.new_method(opts)
  require("cshelper.templates").method(opts)
end

function M.secrets_list()
  require("cshelper.secrets").list()
end

function M.secrets_edit()
  require("cshelper.secrets").edit()
end

return M
