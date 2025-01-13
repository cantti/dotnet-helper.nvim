local M = {}

local options = {
  ["New: C# class"] = require("fzf-dotnet.item_creation").new_class,
  ["Build"] = function()
    vim.pring("build...")
  end,
}

function M.show()
  require("fzf-lua").fzf_exec(vim.tbl_keys(options), {
    winopts = {
      title = "Fzfdotnet commands",
    },
    actions = {
      ["default"] = function(selected, opts)
        options[selected[1]]()
      end,
    },
  })
end

return M
