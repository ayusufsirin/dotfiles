local M = {
  id = "stm32",
  name = "STM32CubeIDE",
  priority = 10,
}

local function stm32()
  return require("config.stm32_debug")
end

local function project_root(project)
  return project and project.root or vim.fn.getcwd()
end

function M.detect(ctx)
  return stm32().current_project(ctx and ctx.path or nil)
end

function M.actions(project)
  return {
    {
      id = "build",
      label = "Build",
      kind = "task",
      run = function()
        return stm32().run_overseer_template("STM32: build")
      end,
    },
    {
      id = "flash",
      label = "Flash",
      kind = "task",
      run = function()
        return stm32().run_overseer_template("STM32: flash")
      end,
    },
    {
      id = "run",
      label = "Run",
      kind = "task",
      run = function()
        return stm32().run_overseer_template("STM32: run")
      end,
    },
    {
      id = "debug",
      label = "Debug",
      kind = "debug",
      run = function()
        return stm32().launch_debug()
      end,
    },
    {
      id = "debug_server",
      label = "OpenOCD",
      kind = "task",
      run = function()
        return stm32().run_overseer_template("STM32: openocd server")
      end,
    },
    {
      id = "clean",
      label = "Clean",
      kind = "task",
      run = function()
        return stm32().run_overseer_template("STM32: clean")
      end,
    },
    {
      id = "compile_db",
      label = "CompileDB",
      kind = "task",
      run = function()
        return stm32().run_overseer_template("STM32: generate compile_commands.json")
      end,
    },
    {
      id = "refresh_managed_build",
      label = "Refresh",
      kind = "task",
      run = function()
        return stm32().run_overseer_template("STM32: refresh managed build")
      end,
    },
    {
      id = "erase",
      label = "Erase",
      kind = "danger",
      run = function()
        return stm32().run_overseer_template("STM32: erase")
      end,
    },
    {
      id = "inspect",
      label = "Inspect",
      kind = "inspect",
      run = function()
        return stm32().inspect_environment(project)
      end,
    },
  }
end

function M.tasks(_project, _ctx, opts)
  local ok, template = pcall(require, "overseer.template.stm32")
  if not ok or type(template.generator) ~= "function" then
    return {}
  end
  return template.generator(opts or { dir = project_root(_project) })
end

function M.health()
  local checks = {}
  local tools = stm32().cubeclt_tools()
  checks[#checks + 1] = { ok = tools.make ~= nil, name = "make" }
  checks[#checks + 1] = { ok = tools.headless ~= nil, name = "STM32CubeCLT headless builder" }
  checks[#checks + 1] = { ok = tools.programmer ~= nil, name = "STM32_Programmer_CLI" }
  checks[#checks + 1] = { ok = tools.openocd ~= nil, name = "openocd" }
  checks[#checks + 1] = { ok = tools.gdb ~= nil, name = "arm-none-eabi-gdb" }
  checks[#checks + 1] = { ok = tools.node ~= nil, name = "node" }
  return checks
end

return M
