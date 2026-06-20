local M = {}

local failures = 0

function M.test(name, fn)
  local ok, err = pcall(fn)
  if ok then
    print("PASS " .. name)
    return
  end

  failures = failures + 1
  print("FAIL " .. name)
  print("  " .. tostring(err))
end

function M.finish()
  if failures > 0 then
    print(string.format("\n%d test(s) failed", failures))
    os.exit(1)
  end

  print("\nAll tests passed")
end

return M
