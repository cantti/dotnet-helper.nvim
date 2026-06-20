local harness = require("harness")
local helpers = require("helpers")

harness.test("is_dotnet_10 returns false for 9.x", function()
  local utils = helpers.reload_utils_with_mocked_system(function()
    return { stdout = "9.0.100\n" }
  end)

  assert(utils.is_dotnet_10() == false)
end)

harness.test("is_dotnet_10 returns true for 10.x", function()
  local utils = helpers.reload_utils_with_mocked_system(function()
    return { stdout = "10.0.101\n" }
  end)

  assert(utils.is_dotnet_10() == true)
end)

harness.test("is_dotnet_10 returns true for 11.x", function()
  local utils = helpers.reload_utils_with_mocked_system(function()
    return { stdout = "11.0.0\n" }
  end)

  assert(utils.is_dotnet_10() == true)
end)

harness.test("is_dotnet_10 errors when stdout is missing", function()
  local utils = helpers.reload_utils_with_mocked_system(function()
    return {}
  end)

  local ok, err = pcall(utils.is_dotnet_10)
  assert(ok == false)
  assert(tostring(err):find("Failed to retrieve .NET version", 1, true) ~= nil)
end)

harness.test("is_dotnet_10 errors on invalid version string", function()
  local utils = helpers.reload_utils_with_mocked_system(function()
    return { stdout = "preview\n" }
  end)

  local ok, err = pcall(utils.is_dotnet_10)
  assert(ok == false)
  assert(tostring(err):find("Failed to parse .NET version", 1, true) ~= nil)
end)

harness.test("is_dotnet_10 caches value and calls system once", function()
  local calls = 0
  local utils = helpers.reload_utils_with_mocked_system(function()
    calls = calls + 1
    return { stdout = "10.0.101\n" }
  end)

  assert(utils.is_dotnet_10() == true)
  assert(utils.is_dotnet_10() == true)
  assert(calls == 1)
end)
