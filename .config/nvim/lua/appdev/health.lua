local M = {}

local function health()
  return vim.health or require("health")
end

local function start(name)
  local h = health()
  if h.start then
    h.start(name)
  else
    h.report_start(name)
  end
end

local function ok(message)
  local h = health()
  if h.ok then
    h.ok(message)
  else
    h.report_ok(message)
  end
end

local function warn(message)
  local h = health()
  if h.warn then
    h.warn(message)
  else
    h.report_warn(message)
  end
end

function M.check()
  start("appdev.nvim")

  ok("appdev.nvim loaded")

  for _, plugin in ipairs({
    "dap",
    "overseer",
    "dapui",
  }) do
    local loaded = pcall(require, plugin)
    if loaded then
      ok(plugin .. " available")
    else
      warn(plugin .. " not loaded or unavailable; related appdev features will lazy-load or degrade")
    end
  end

  for _, adapter in ipairs(require("appdev.registry").list()) do
    ok("registered adapter: " .. adapter.id)
  end
end

return M
