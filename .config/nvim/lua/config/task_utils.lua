local M = {}

function M.shell_command(command)
  return {
    cmd = "bash",
    args = { "-lc", command },
  }
end

function M.default_components()
  return { "default" }
end

function M.quickfix_diagnostics_components()
  return {
    "default",
    { "on_output_quickfix", open = false },
    { "on_result_diagnostics", remove_on_restart = true },
  }
end

function M.task(command, opts)
  opts = opts or {}

  local task = M.shell_command(command)
  task.name = opts.name
  task.cwd = opts.cwd
  task.components = opts.components or M.default_components()

  return task
end

function M.template(name, desc, builder)
  return {
    name = name,
    desc = desc,
    builder = builder,
  }
end

return M
