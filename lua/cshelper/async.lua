local M = {}

function M.wrap(fn, ...)
  local co = coroutine.running()
  assert(co, "wrap must be called inside a coroutine")

  local resumed = false
  local function resume_co(...)
    if resumed then
      return
    end
    resumed = true
    local ok, err = coroutine.resume(co, ...)
    if not ok then
      error(debug.traceback(co, err), 0)
    end
  end

  local args = { ... }
  table.insert(args, vim.schedule_wrap(resume_co))

  fn(unpack(args))

  return coroutine.yield()
end

function M.select(items, opts)
  return M.wrap(vim.ui.select, items, opts)
end

function M.input(opts)
  return M.wrap(vim.ui.input, opts)
end

function M.system(args)
  return M.wrap(vim.system, args, { text = true })
end

function M.async(fn)
  return function(...)
    local running = coroutine.running()
    if running then
      -- Already in a coroutine: just run it here (lets returns propagate).
      return fn(...)
    end

    local co = coroutine.create(fn)
    local ok, res = coroutine.resume(co, ...)
    if not ok then
      error(debug.traceback(co, res), 0)
    end
    -- If fn returned immediately (no yield), propagate its returns:
    if coroutine.status(co) == "dead" then
      return res
    end
    -- Otherwise it yielded and will be resumed by your a.wrap callbacks.
    -- We intentionally return nothing in this case.
  end
end

return M
