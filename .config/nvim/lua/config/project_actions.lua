local M = {}

local providers = {}
local registered_callbacks = {}
local handlers_registered = false

local function load_overseer()
  local ok, lazy = pcall(require, "lazy")
  if ok then
    pcall(lazy.load, { plugins = { "overseer.nvim" } })
  end
end

local function load_dap()
  local ok, debug_ui = pcall(require, "config.debug_ui")
  if not ok then
    return false
  end

  return debug_ui.load_dap() ~= nil
end

local function register_action_callback(action)
  if registered_callbacks[action.callback] then
    return
  end

  _G[action.callback] = action.run
  registered_callbacks[action.callback] = true
end

function M.register_provider(provider)
  if type(provider) ~= "table" or type(provider.name) ~= "string" then
    error("project action provider requires a name")
  end

  if type(provider.detect) ~= "function" then
    error("project action provider " .. provider.name .. " requires detect")
  end

  if type(provider.actions) ~= "table" then
    error("project action provider " .. provider.name .. " requires actions")
  end

  for _, action in ipairs(provider.actions) do
    if type(action.label) ~= "string" or type(action.callback) ~= "string" or type(action.run) ~= "function" then
      error("project action provider " .. provider.name .. " has an invalid action")
    end
  end

  provider.priority = provider.priority or 100
  providers[provider.name] = provider

  if handlers_registered then
    for _, action in ipairs(provider.actions) do
      register_action_callback(action)
    end
  end
end

function M.active_provider(path)
  local ordered = {}
  for _, provider in pairs(providers) do
    ordered[#ordered + 1] = provider
  end
  table.sort(ordered, function(a, b)
    return a.priority < b.priority
  end)

  for _, provider in ipairs(ordered) do
    local ok, detected = pcall(provider.detect, path)
    if ok and detected then
      return provider
    end
  end
end

function M.inactive_buttons(path)
  local provider = M.active_provider(path)
  if not provider then
    return {}
  end

  local buttons = {}
  for _, action in ipairs(provider.actions) do
    buttons[#buttons + 1] = {
      callback = action.callback,
      label = action.label,
    }
  end

  return buttons
end

function M.setup_click_handlers()
  handlers_registered = true

  for _, provider in pairs(providers) do
    for _, action in ipairs(provider.actions) do
      register_action_callback(action)
    end
  end
end

local function register_ros2_provider()
  M.register_provider({
    name = "Ros",
    detect = function(path)
      return require("config.ros2_debug").current_workspace(path) ~= nil
    end,
    actions = {
      {
        label = "Build",
        callback = "DebugRosBuild",
        run = function()
          load_overseer()
          require("config.ros2_debug").build_current_package()
        end,
      },
      {
        label = "Run",
        callback = "DebugRosRun",
        run = function()
          load_overseer()
          require("config.ros2_debug").run_node()
        end,
      },
      {
        label = "Debug Py",
        callback = "DebugRosPython",
        run = function()
          if load_dap() then
            require("config.ros2_debug").launch_python_node()
          end
        end,
      },
      {
        label = "Debug C++",
        callback = "DebugRosCpp",
        run = function()
          if load_dap() then
            require("config.ros2_debug").launch_cpp_node()
          end
        end,
      },
      {
        label = "Attach",
        callback = "DebugRosAttach",
        run = function()
          if load_dap() then
            require("config.ros2_debug").attach_process()
          end
        end,
      },
    },
  })
end

register_ros2_provider()

local function register_stm32_provider()
  local stm32_debug = require("config.stm32_debug")

  M.register_provider({
    name = "Stm32",
    priority = 10,
    detect = function(path)
      return stm32_debug.current_project(path) ~= nil
    end,
    actions = {
      {
        label = "Build",
        callback = "DebugStm32Build",
        run = function()
          load_overseer()
          stm32_debug.run_overseer_template("STM32: build")
        end,
      },
      {
        label = "Clean",
        callback = "DebugStm32Clean",
        run = function()
          load_overseer()
          stm32_debug.run_overseer_template("STM32: clean")
        end,
      },
      {
        label = "CompileDB",
        callback = "DebugStm32CompileDb",
        run = function()
          load_overseer()
          stm32_debug.run_overseer_template("STM32: generate compile_commands.json")
        end,
      },
      {
        label = "Flash",
        callback = "DebugStm32Flash",
        run = function()
          load_overseer()
          stm32_debug.run_overseer_template("STM32: flash")
        end,
      },
      {
        label = "Erase",
        callback = "DebugStm32Erase",
        run = function()
          load_overseer()
          stm32_debug.run_overseer_template("STM32: erase")
        end,
      },
      {
        label = "OpenOCD",
        callback = "DebugStm32OpenOCD",
        run = function()
          load_overseer()
          stm32_debug.run_overseer_template("STM32: openocd server")
        end,
      },
      {
        label = "Debug",
        callback = "DebugStm32Debug",
        run = function()
          if load_dap() then
            stm32_debug.launch_debug()
          end
        end,
      },
      {
        label = "Inspect",
        callback = "DebugStm32Inspect",
        run = function()
          stm32_debug.inspect_environment()
        end,
      },
    },
  })
end

register_stm32_provider()

return M
