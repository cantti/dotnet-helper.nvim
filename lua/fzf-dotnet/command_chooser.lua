local M = {}

local options = {
  {
    label = "New: C# class",
    cmd = require("fzf-dotnet.item_creation").new_class,
  },
  {
    label = "Build: solution",
    cmd = require("fzf-dotnet.build").build_solution,
  },
  {
    label = "Build: project or solution",
    cmd = require("fzf-dotnet.build").build_project_or_solution,
  },
}

local function get_labels()
  local labels = {}
  for _, option in ipairs(options) do
    table.insert(labels, option.label)
  end
  return labels
end

local function get_cmd(label)
  local labels = {}
  for _, option in ipairs(options) do
    if option.label == label then
      return option.cmd
    end
  end
end

function M.show()
  require("fzf-lua").fzf_exec(get_labels(), {
    winopts = {
      title = "Fzfdotnet commands",
    },
    actions = {
      ["default"] = function(selected, opts)
        get_cmd(selected[1])()
      end,
    },
  })
end

return M
