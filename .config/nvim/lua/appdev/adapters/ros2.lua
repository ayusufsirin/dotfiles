local M = {
  id = "ros2",
  name = "ROS2",
  priority = 100,
}

local function ros2()
  return require("config.ros2_debug")
end

function M.detect(ctx)
  return ros2().current_workspace(ctx and ctx.path or nil)
end

function M.actions(project)
  return {
    {
      id = "build",
      label = "Build",
      kind = "task",
      run = function()
        return ros2().build_current_package()
      end,
    },
    {
      id = "run",
      label = "Run",
      kind = "task",
      run = function()
        return ros2().run_node()
      end,
    },
    {
      id = "debug",
      label = "Debug",
      kind = "debug",
      run = function()
        return ros2().launch_python_node()
      end,
    },
    {
      id = "debug_cpp",
      label = "Debug C++",
      kind = "debug",
      run = function()
        return ros2().launch_cpp_node()
      end,
    },
    {
      id = "attach",
      label = "Attach",
      kind = "debug",
      run = function()
        return ros2().attach_process()
      end,
    },
    {
      id = "inspect",
      label = "Inspect",
      kind = "inspect",
      run = function()
        return ros2().inspect_environment(project)
      end,
    },
  }
end

function M.tasks(_project, _ctx, opts)
  local ok, template = pcall(require, "overseer.template.ros2")
  if not ok or type(template.generator) ~= "function" then
    return {}
  end
  return template.generator(opts or {})
end

function M.health()
  local checks = {}
  checks[#checks + 1] = { ok = vim.fn.executable("colcon") == 1, name = "colcon" }
  return checks
end

return M
