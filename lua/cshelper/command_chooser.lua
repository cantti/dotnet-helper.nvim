local M = {}

local options = {
  {
    label = "New: C# class",
    cmd = require("cshelper.templates").class,
  },
  {
    label = "New: C# Api Controller",
    cmd = require("cshelper.templates").apicontroller,
  },
  {
    label = "Build",
    cmd = require("cshelper.build").build,
  },
  {
    label = "Build: project or solution",
    cmd = require("cshelper.build").build_project_or_solution,
  },
  {
    label = "Run: project",
    cmd = require("cshelper.run").run_project,
  },
  {
    label = "Clean",
    cmd = require("cshelper.clean").clean,
  },
  {
    label = "Clean: project or solution",
    cmd = require("cshelper.clean").clean_project_or_solution,
  },
  {
    label = "Secrets: edit",
    cmd = require("cshelper.secrets").edit_secrets,
  },
  {
    label = "Secrets: list",
    cmd = require("cshelper.secrets").list_secrets,
  },
  {
    label = "Fix namespace",
    cmd = require("cshelper.fix_namespace").fix_namespace,
  },
}

local labels = vim.tbl_map(function(x)
  return x.label
end, options)

local function get_cmd(label)
  return vim.tbl_filter(function(x)
    return x.label == label
  end, options)[1].cmd
end

function M.show()
  vim.ui.select(labels, {
    prompt = "Choose an option:",
  }, function(choice)
    if not choice then
      return
    end
    get_cmd(choice)()
  end)
end

return M
