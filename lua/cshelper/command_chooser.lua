local M = {}

local options = {
  {
    label = "New class: file scoped namespace",
    cmd = function()
      require("cshelper").new_class({ blockns = false })
    end,
  },
  {
    label = "New class: block namespace",
    cmd = function()
      require("cshelper").new_api_controller({ blockns = true })
    end,
  },
  {
    label = "New api controller: file scoped namespace",
    cmd = function()
      require("cshelper").new_api_controller({ blockns = false })
    end,
  },
  {
    label = "New api controller: block namespace",
    cmd = function()
      require("cshelper").new_api_controller({ blockns = false })
    end,
  },
  {
    label = "Secrets: edit",
    cmd = function()
      require("cshelper").secrets_edit()
    end,
  },
  {
    label = "Secrets: list",
    cmd = function()
      require("cshelper").secrets_list()
    end,
  },
  {
    label = "Fix namespace: buffer, update usings",
    cmd = function()
      require("cshelper").fix_ns({ mode = "buffer", update_usings = true })
    end,
  },
  {
    label = "Fix namespace: buffer, do not update usings",
    cmd = function()
      require("cshelper").fix_ns({ mode = "buffer", update_usings = false })
    end,
  },
  {
    label = "Fix namespace: directory, update usings",
    cmd = function()
      require("cshelper").fix_ns({ mode = "directory", update_usings = true })
    end,
  },
  {
    label = "Fix namespace: directory, do not update usings",
    cmd = function()
      require("cshelper").fix_ns({ mode = "directory", update_usings = false })
    end,
  },
}

function M.show()
  vim.ui.select(options, {
    prompt = "Choose an option:",
    format_item = function(item)
      return item.label
    end,
  }, function(choice)
    if not choice then
      return
    end
    choice.cmd()
  end)
end

return M
