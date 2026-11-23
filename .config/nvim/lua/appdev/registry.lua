local M = {}

local adapters = {}

local function validate_adapter(adapter)
  vim.validate({
    adapter = { adapter, "table" },
    id = { adapter.id, "string" },
    name = { adapter.name, "string" },
    detect = { adapter.detect, "function" },
    actions = { adapter.actions, "function" },
  })
end

function M.register(adapter)
  validate_adapter(adapter)
  adapter.priority = adapter.priority or 100
  adapters[adapter.id] = adapter
end

function M.unregister(id)
  adapters[id] = nil
end

function M.get(id)
  return adapters[id]
end

function M.list()
  local ordered = {}
  for _, adapter in pairs(adapters) do
    ordered[#ordered + 1] = adapter
  end

  table.sort(ordered, function(left, right)
    if left.priority == right.priority then
      return left.id < right.id
    end
    return left.priority < right.priority
  end)

  return ordered
end

function M.detect(ctx)
  for _, adapter in ipairs(M.list()) do
    local ok, project = pcall(adapter.detect, ctx)
    if ok and project then
      return {
        adapter = adapter,
        project = project,
        ctx = ctx,
      }
    end
  end
end

return M
