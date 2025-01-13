local M = {} -- M stands for module, a naming convention

local item_creation = require("fzf-lua-dotnet.item-creation")

function M.setup()
  vim.api.nvim_create_user_command("CsharpClass", function()
    item_creation.new_class()
  end, {})
end

return M
