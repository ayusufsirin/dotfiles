local ros2 = require("config.ros2_debug")
local task_utils = require("config.task_utils")

return {
  name = "ros2",
  generator = function(opts)
    if not ros2.current_workspace(opts and opts.dir or nil) then
      return {}
    end

    return {
      task_utils.template("ROS2: build current package", "Build current package and dependencies with debug flags", function()
        local command, workspace, package = ros2.build_command()
        if not command or not workspace then
          return nil
        end

        return task_utils.task(command, {
          name = "ROS2: build " .. (package and package.name or "workspace"),
          cwd = workspace.root,
          components = task_utils.quickfix_diagnostics_components(),
        })
      end),

      task_utils.template("ROS2: build workspace", "Build the whole workspace with debug flags", function()
        local workspace = ros2.require_workspace()
        if not workspace then
          return nil
        end

        local command = ros2.workspace_build_command(workspace)
        return task_utils.task(command, {
          name = "ROS2: build workspace",
          cwd = workspace.root,
          components = task_utils.quickfix_diagnostics_components(),
        })
      end),

      task_utils.template("ROS2: run installed node", "Pick and run an installed ROS2 node", function()
        local item = ros2.select_executable_sync()
        if not item then
          return nil
        end

        local command, workspace = ros2.run_command(item)
        if not command or not workspace then
          return nil
        end

        return task_utils.task(command, {
          name = "ROS2: run " .. item.label,
          cwd = workspace.root,
        })
      end),
    }
  end,
}
