local M = {}

local callbacks_registered = false

local function callback_name(action_id)
  return "AppDevAction_" .. action_id:gsub("[^%w_]", "_")
end

local function button(callback, label)
  return table.concat({
    "%@v:lua.",
    callback,
    "@",
    " ",
    label,
    " ",
    "%T",
  })
end

function M.setup_click_handlers()
  if callbacks_registered then
    return
  end
  callbacks_registered = true

  for _, id in ipairs({
    "build",
    "run",
    "debug",
    "debug_cpp",
    "attach",
    "flash",
    "clean",
    "compile_db",
    "refresh_managed_build",
    "debug_server",
    "erase",
    "inspect",
  }) do
    _G[callback_name(id)] = function()
      require("appdev").run_action(id)
    end
  end
end

function M.inactive_buttons(path)
  M.setup_click_handlers()

  local active = require("appdev.context").active(path)
  local result = {}
  for _, action in ipairs(require("appdev.actions").for_active(active)) do
    result[#result + 1] = {
      callback = callback_name(action.id),
      label = action.label,
      id = action.id,
      kind = action.kind,
    }
  end

  return result
end

function M.file_winbar_prefix()
  local chunks = {}
  for _, action in ipairs(M.inactive_buttons()) do
    chunks[#chunks + 1] = button(action.callback, action.label)
  end
  return table.concat(chunks)
end

return M
