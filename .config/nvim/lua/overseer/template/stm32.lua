local stm32 = require("config.stm32_debug")
local task_utils = require("config.task_utils")
local dev_utils = require("config.dev_utils")

local M = {}

local function missing_tool_task(tools, purpose)
  local message = "STM32 "
    .. purpose
    .. " requires one of: "
    .. table.concat(tools, ", ")
    .. ". Install one and rerun this task."

  return task_utils.task("echo " .. vim.fn.shellescape(message), {
    name = "STM32: missing tool for " .. purpose,
    cwd = vim.fn.getcwd(),
    components = task_utils.default_components(),
  })
end

local function config_dir(project)
  return project.default_config
end

function M.build_task(project)
  local command = stm32.build_current_config(project)
  return task_utils.task(command, {
    name = "STM32: build " .. project.project_name,
    cwd = project.root,
    components = task_utils.quickfix_diagnostics_components(),
  })
end

function M.clean_task(project)
  local command = stm32.clean_current_config(project)
  return task_utils.task(command, {
    name = "STM32: clean " .. project.project_name,
    cwd = project.root,
    components = task_utils.default_components(),
  })
end

function M.compile_db_task(project)
  local command, _config, note = stm32.generate_compile_commands(project)
  if not command then
    return missing_tool_task({ "compiledb", "bear" }, "compile_commands.json generation")
  end

  local tool = command:match("^(%S+)")
  local name = "STM32: generate compile_commands.json (" .. tool .. ") " .. project.project_name
  if note then
    name = name .. " [" .. note .. "]"
  end

  return task_utils.task(command, {
    name = name,
    cwd = project.root,
    components = task_utils.quickfix_diagnostics_components(),
  })
end

function M.flash_task(project)
  local candidates = project.elf_candidates or {}
  local selected
  local command

  if #candidates == 0 then
    selected = vim.fn.input("Path to ELF: ", dev_utils.join(project.root, config_dir(project), ""), "file")
    if selected == "" then
      return nil
    end
    command = "STM32_Programmer_CLI -c port=SWD -w " .. vim.fn.shellescape(selected) .. " -v -rst"
  else
    command, selected = stm32.flash_elf(project)
    if not command then
      return nil
    end
  end

  return task_utils.task(command, {
    name = "STM32: flash " .. vim.fn.fnamemodify(selected, ":t"),
    cwd = project.root,
    components = task_utils.default_components(),
  })
end

function M.erase_task(project)
  local confirm = vim.fn.input("Type 'erase' to confirm full chip erase: ")
  if confirm ~= "erase" then
    vim.notify("STM32 erase cancelled", vim.log.levels.INFO)
    return nil
  end

  return task_utils.task("STM32_Programmer_CLI -c port=SWD -e all", {
    name = "STM32: erase chip",
    cwd = project.root,
    components = task_utils.default_components(),
  })
end

function M.openocd_task(project)
  local command, err = stm32.start_openocd(project)
  if not command then
    if err and err:match("openocd is not on PATH") then
      return missing_tool_task({ "openocd" }, "OpenOCD server")
    end

    local target_cfg = vim.fn.input("Target OpenOCD config (e.g. target/stm32f4x.cfg): ", "target/stm32f4x.cfg", "file")
    if target_cfg == "" then
      return nil
    end

    command = stm32.start_openocd(project, { target = target_cfg })
    if not command then
      return nil
    end
  end

  return task_utils.task(command, {
    name = "STM32: openocd server",
    cwd = project.root,
    components = task_utils.default_components(),
  })
end

return {
  name = "stm32",
  generator = function(opts)
    local project = stm32.current_project(opts and opts.dir or nil)
    if not project then
      return {}
    end

    return {
      task_utils.template("STM32: build", "Build the STM32 project with make", function()
        return M.build_task(project)
      end),

      task_utils.template("STM32: clean", "Clean the STM32 build directory", function()
        return M.clean_task(project)
      end),

      task_utils.template("STM32: generate compile_commands.json", "Generate compile_commands.json using compiledb or bear", function()
        return M.compile_db_task(project)
      end),

      task_utils.template("STM32: flash", "Flash the selected ELF to the target", function()
        return M.flash_task(project)
      end),

      task_utils.template("STM32: erase", "Erase the entire STM32 chip", function()
        return M.erase_task(project)
      end),

      task_utils.template("STM32: openocd server", "Start OpenOCD server for STM32 debugging", function()
        return M.openocd_task(project)
      end),
    }
  end,
}
