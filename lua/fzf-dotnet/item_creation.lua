local M = {}
local fs = require("fzf-dotnet.fs")
local utils = require("fzf-dotnet.utils")

function M.new_class()
  local locations = utils.get_dir_options(".")

  require("fzf-lua").fzf_exec(locations, {
    winopts = {
      title = "Select folder",
    },
    actions = {
      ["default"] = function(selected, opts)
        local location = selected[1]
        local class_name = vim.fn.input("Enter name: ")
        local file_name = class_name .. ".cs"

        local file_path = fs.join_paths({ vim.fn.getcwd(), location, file_name })

        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(buf, file_path)
        vim.api.nvim_buf_set_option(buf, "filetype", "cs")
        vim.api.nvim_set_current_buf(buf)

        local namespace = utils.get_namespace_for_file(file_path)
        if not namespace then
          return
        end

        local lines = {
          "namespace " .. namespace .. ";",
          "",
          "public class " .. class_name,
          "{",
          "}",
        }
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        -- vim.cmd("write")
      end,
    },
  })
end

function M.new_api_controller()
  local locations = utils.get_dir_options(".")

  require("fzf-lua").fzf_exec(locations, {
    winopts = {
      title = "Select folder",
    },
    actions = {
      ["default"] = function(selected)
        local location = selected[1]
        local class_name = vim.fn.input("Enter name: ")
        local file_name = class_name .. ".cs"

        local file_path = fs.join_paths({ vim.fn.getcwd(), location, file_name })

        local buf = vim.api.nvim_create_buf(true, false)
        vim.api.nvim_buf_set_name(buf, file_path)
        vim.api.nvim_buf_set_option(buf, "filetype", "cs")
        vim.api.nvim_set_current_buf(buf)

        local namespace = utils.get_namespace_for_file(file_path)
        if not namespace then
          return
        end

        local lines = {
          "using Microsoft.AspNetCore.Http;",
          "using Microsoft.AspNetCore.Mvc;",
          "",
          "namespace " .. namespace .. ";",
          "",
          '[Route("api/[controller]")]',
          "[ApiController]",
          "public class " .. class_name .. " : ControllerBase",
          "{",
          "}",
        }
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
        -- vim.cmd("write")
      end,
    },
  })
end

return M
