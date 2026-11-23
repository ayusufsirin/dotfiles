local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.WARN, { title = "appdev.nvim" })
end

function M.load()
  if not package.loaded["overseer"] then
    local ok_lazy, lazy = pcall(require, "lazy")
    if ok_lazy then
      pcall(lazy.load, { plugins = { "overseer.nvim" } })
    end
  end

  local ok, overseer = pcall(require, "overseer")
  if not ok then
    notify("overseer.nvim is required for appdev tasks", vim.log.levels.ERROR)
    return nil
  end

  return overseer
end

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
  local task
  if type(command) == "table" then
    task = vim.deepcopy(command)
  else
    task = M.shell_command(command)
  end

  task.name = opts.name or task.name
  task.cwd = opts.cwd or task.cwd
  task.components = opts.components or task.components or M.default_components()
  return task
end

function M.template(name, desc, builder)
  return {
    name = name,
    desc = desc,
    builder = builder,
  }
end

function M.run_template(name, root)
  local overseer = M.load()
  if not overseer then
    return false
  end

  overseer.run_task({
    name = name,
    search_params = {
      dir = root or vim.fn.getcwd(),
      filetype = vim.bo.filetype,
    },
  }, function(task)
    if task and require("appdev.config").get().overseer.open_on_run then
      overseer.open({ enter = false })
    end
  end)

  return true
end

function M.templates(opts)
  local active = require("appdev.context").active(opts and opts.dir or nil)
  if not active or type(active.adapter.tasks) ~= "function" then
    return {}
  end

  local ok, templates = pcall(active.adapter.tasks, active.project, active.ctx, opts or {})
  if not ok or type(templates) ~= "table" then
    return {}
  end

  return templates
end

return M
