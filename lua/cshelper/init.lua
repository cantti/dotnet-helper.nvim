local M = {}

function M.setup() end

function M.secrets_list()
  require("cshelper.secrets"):new():list()
end

function M.secrets_edit()
  require("cshelper.secrets"):new():edit()
end

function M.templates()
  require("cshelper.template_chooser").show()
end

function M.nuget_search()
  require("cshelper.nuget"):new():search()
end

return M
