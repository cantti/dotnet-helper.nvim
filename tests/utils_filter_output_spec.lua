local harness = require("harness")
local helpers = require("helpers")

harness.test("filter_dotnet_output returns only data lines", function()
  local utils = helpers.reload_utils_with_mocked_system(function()
    return { stdout = "10.0.101\n" }
  end)

  local text = table.concat({
    "info: booting",
    "data: first",
    "error: oops",
    "data: second",
  }, "\n")

  assert(utils.filter_dotnet_output(text, "data") == "first\nsecond")
end)

harness.test("filter_dotnet_output handles windows newlines", function()
  local utils = helpers.reload_utils_with_mocked_system(function()
    return { stdout = "10.0.101\n" }
  end)

  local text = "data: one\r\ndata: two\r\ninfo: done"
  assert(utils.filter_dotnet_output(text, "data") == "one\ntwo")
end)

harness.test("filter_dotnet_output returns empty when no matches", function()
  local utils = helpers.reload_utils_with_mocked_system(function()
    return { stdout = "10.0.101\n" }
  end)

  local text = "info: one\nerror: two"
  assert(utils.filter_dotnet_output(text, "data") == "")
end)

harness.test("filter_dotnet_output trims optional space after prefix", function()
  local utils = helpers.reload_utils_with_mocked_system(function()
    return { stdout = "10.0.101\n" }
  end)

  local text = "data:value\ndata: value"
  assert(utils.filter_dotnet_output(text, "data") == "value\nvalue")
end)
