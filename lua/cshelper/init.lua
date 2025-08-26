local M = {}

local nuget = require("cshelper.nuget"):new()
local secrets = require("cshelper.secrets"):new()

function M.setup() end

function M.secrets_list()
  secrets:list()
end

function M.secrets_edit()
  secrets:edit()
end

function M.nuget_search()
  nuget:search()
end

function M.templates()
  require("cshelper.template_chooser").show()
end

return M
