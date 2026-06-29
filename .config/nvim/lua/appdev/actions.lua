local M = {}

local function action_sort(left, right)
  local order = {
    build = 10,
    run = 20,
    debug = 30,
    attach = 40,
    flash = 50,
    clean = 60,
    compile_db = 70,
    refresh_managed_build = 75,
    debug_server = 80,
    erase = 90,
    inspect = 100,
  }

  local left_order = order[left.id] or 1000
  local right_order = order[right.id] or 1000
  if left_order == right_order then
    return (left.label or left.id) < (right.label or right.id)
  end
  return left_order < right_order
end

function M.for_active(active)
  if not active then
    return {}
  end

  local ok, actions = pcall(active.adapter.actions, active.project, active.ctx)
  if not ok or type(actions) ~= "table" then
    return {}
  end

  local result = {}
  for _, action in ipairs(actions) do
    if type(action) == "table" and type(action.id) == "string" and type(action.run) == "function" then
      action.label = action.label or action.id
      action.kind = action.kind or "action"
      result[#result + 1] = action
    end
  end

  table.sort(result, action_sort)
  return result
end

function M.find(active, id)
  for _, action in ipairs(M.for_active(active)) do
    if action.id == id then
      return action
    end
  end
end

return M
