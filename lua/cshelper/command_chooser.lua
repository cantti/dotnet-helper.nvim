local M = {}

local options = {
  {
    label = "New class: file scoped namespace",
    cmd = function()
      require("cshelper").new_class({ use_block_ns = false })
    end,
  },
  {
    label = "New class: block namespace",
    cmd = function()
      require("cshelper").new_class({ use_block_ns = true })
    end,
  },
  {
    label = "New api controller: file scoped namespace",
    cmd = function()
      require("cshelper").new_api_controller({ use_block_ns = false })
    end,
  },
  {
    label = "New api controller: block namespace",
    cmd = function()
      require("cshelper").new_api_controller({ use_block_ns = true })
    end,
  },
  {
    label = "New property: required",
    cmd = function()
      require("cshelper").new_property()
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
    label = "Fix namespace: buffer",
    cmd = function()
      require("cshelper").fix_ns_buf()
    end,
    cho,
  },
  {
    label = "Fix namespace: directory",
    cmd = function()
      require("cshelper").fix_ns_dir()
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
