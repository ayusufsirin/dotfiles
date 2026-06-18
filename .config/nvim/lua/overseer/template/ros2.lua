local ros2 = require("config.ros2_debug")

local function template(name, desc, builder)
  return {
    name = name,
    desc = desc,
    builder = builder,
  }
end

local function command_components(command)
  return {
    cmd = "bash",
    args = { "-lc", command },
  }
end

return {
  name = "ros2",
  generator = function(opts)
    if not ros2.current_workspace(opts and opts.dir or nil) then
      return {}
    end

    return {
      template("ROS2: build current package", "Build current package and dependencies with debug flags", function()
        local command, workspace, package = ros2.build_command()
        if not command or not workspace then
          return nil
        end

        local task = command_components(command)
        task.name = "ROS2: build " .. (package and package.name or "workspace")
        task.cwd = workspace.root
        task.components = {
          "default",
          { "on_output_quickfix", open = false },
          { "on_result_diagnostics", remove_on_restart = true },
        }
        return task
      end),

      template("ROS2: build workspace", "Build the whole workspace with debug flags", function()
        local workspace = ros2.require_workspace()
        if not workspace then
          return nil
        end

        local command = ros2.workspace_build_command(workspace)
        local task = command_components(command)
        task.name = "ROS2: build workspace"
        task.cwd = workspace.root
        task.components = {
          "default",
          { "on_output_quickfix", open = false },
          { "on_result_diagnostics", remove_on_restart = true },
        }
        return task
      end),

      template("ROS2: run installed node", "Pick and run an installed ROS2 node", function()
        local item = ros2.select_executable_sync()
        if not item then
          return nil
        end

        local command, workspace = ros2.run_command(item)
        if not command or not workspace then
          return nil
        end

        local task = command_components(command)
        task.name = "ROS2: run " .. item.label
        task.cwd = workspace.root
        task.components = {
          "default",
        }
        return task
      end),
    }
  end,
}
