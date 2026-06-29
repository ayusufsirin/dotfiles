local config = require("appdev.config")
local registry = require("appdev.registry")
local context = require("appdev.context")
local actions = require("appdev.actions")

local M = {}

local setup_done = false

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.WARN, { title = "appdev.nvim" })
end

local function active_or_notify(path)
  local active = context.active(path)
  if active then
    return active
  end

  notify("No appdev adapter detected for the current project")
end

local function select_and_run(filter)
  local active = active_or_notify()
  if not active then
    return
  end

  local candidates = vim.tbl_filter(function(action)
    return not filter or filter(action)
  end, actions.for_active(active))

  if #candidates == 0 then
    notify("No matching appdev actions for " .. active.adapter.name)
    return
  end

  if #candidates == 1 then
    return candidates[1].run(active.project, active.ctx, {})
  end

  vim.ui.select(candidates, {
    prompt = "AppDev action",
    format_item = function(item)
      return item.label
    end,
  }, function(item)
    if item then
      item.run(active.project, active.ctx, {})
    end
  end)
end

local function create_commands()
  vim.api.nvim_create_user_command("AppDevBuild", function()
    M.run_action("build")
  end, {})

  vim.api.nvim_create_user_command("AppDevRun", function()
    M.run_action("run")
  end, {})

  vim.api.nvim_create_user_command("AppDevDebug", function()
    M.run_action("debug")
  end, {})

  vim.api.nvim_create_user_command("AppDevInspect", function()
    M.run_action("inspect")
  end, {})

  vim.api.nvim_create_user_command("AppDevRefresh", function()
    context.clear()
    notify("appdev project cache cleared", vim.log.levels.INFO)
  end, {})

  vim.api.nvim_create_user_command("AppDevAction", function(command)
    if command.args ~= "" then
      M.run_action(command.args)
    else
      select_and_run()
    end
  end, {
    nargs = "?",
    complete = function()
      local active = context.active()
      return vim.tbl_map(function(action)
        return action.id
      end, actions.for_active(active))
    end,
  })

  vim.api.nvim_create_user_command("AppDevTask", function()
    select_and_run(function(action)
      return action.kind == "task" or action.kind == "danger"
    end)
  end, {})
end

function M.setup(opts)
  config.setup(opts)

  if config.get().adapters.ros2 then
    registry.register(require("appdev.adapters.ros2"))
  end
  if config.get().adapters.stm32 then
    registry.register(require("appdev.adapters.stm32"))
  end

  if not setup_done then
    setup_done = true
    create_commands()
    require("appdev.integrations.ui").setup_click_handlers()
  end

  return M
end

function M.register(adapter)
  registry.register(adapter)
end

function M.active(path)
  return context.active(path)
end

function M.actions(path)
  return actions.for_active(context.active(path))
end

function M.run_action(id, opts)
  opts = opts or {}
  local active = active_or_notify(opts.path)
  if not active then
    return nil
  end

  local action = actions.find(active, id)
  if not action then
    notify("Action '" .. id .. "' is not available for " .. active.adapter.name)
    return nil
  end

  return action.run(active.project, active.ctx, opts)
end

return M
