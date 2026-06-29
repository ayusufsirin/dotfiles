vim.opt.runtimepath:prepend(vim.fn.getcwd())

local appdev = require("appdev")

appdev.setup({
  adapters = {
    stm32 = {
      cubeclt = {
        install_dir = vim.fn.getcwd() .. "/tests/fixtures/fake_cubeclt",
        workspace_dir = vim.fn.getcwd() .. "/tests/fixtures/.cubeclt-workspace",
      },
    },
  },
  project_config = {
    trusted_lua = false,
  },
})

local root = vim.fn.getcwd()

local function assert_eq(actual, expected, message)
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", message, vim.inspect(expected), vim.inspect(actual)))
  end
end

local ros2_path = root .. "/tests/fixtures/ros2_ws/src/pkg_a/package.xml"
local ros2_active = appdev.active(ros2_path)
assert(ros2_active, "ROS2 fixture should be detected")
assert_eq(ros2_active.adapter.id, "ros2", "ROS2 adapter id")

local stm32_path = root .. "/tests/fixtures/stm32_proj/Debug/Makefile"
local stm32_active = appdev.active(stm32_path)
assert(stm32_active, "STM32 fixture should be detected")
assert_eq(stm32_active.adapter.id, "stm32", "STM32 adapter id")

local mixed_path = root .. "/tests/fixtures/mixed_proj/Debug/Makefile"
local mixed_active = appdev.active(mixed_path)
assert(mixed_active, "Mixed fixture should be detected")
assert_eq(mixed_active.adapter.id, "stm32", "STM32 should outrank ROS2 in mixed projects")

local action_ids = {}
for _, action in ipairs(appdev.actions(stm32_path)) do
  action_ids[action.id] = true
end

assert(action_ids.build, "STM32 build action should exist")
assert(action_ids.debug, "STM32 debug action should exist")
assert(action_ids.inspect, "STM32 inspect action should exist")

local stm32 = require("config.stm32_debug")
local managed_path = root .. "/tests/fixtures/stm32_managed_only/Core/Src/main.c"
local managed_project = stm32.current_project(managed_path)
assert(managed_project, "Managed STM32 fixture should be detected")
assert_eq(managed_project.configs[1].source, "managed_build", "Managed fixture config source")
assert_eq(managed_project.mcu, "STM32F722RETx", "Managed fixture MCU")
assert_eq(managed_project.openocd_target, "target/stm32f7x.cfg", "Managed fixture inferred OpenOCD target")

local build_command = stm32.build_current_config(managed_project)
assert(build_command:match("headless%-build%.sh"), "Managed fixture should use CubeCLT headless build")
assert(build_command:match("%-build") and build_command:match("stm32_managed_only/Debug"), "Managed fixture should build Debug config")

print("appdev smoke tests passed")
