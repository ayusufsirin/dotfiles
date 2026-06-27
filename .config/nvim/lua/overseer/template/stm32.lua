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
  local cfg = config_dir(project)
  return task_utils.task("make -C " .. vim.fn.shellescape(cfg), {
    name = "STM32: build " .. project.project_name,
    cwd = project.root,
    components = task_utils.quickfix_diagnostics_components(),
  })
end

function M.clean_task(project)
  local cfg = config_dir(project)
  return task_utils.task("make clean -C " .. vim.fn.shellescape(cfg), {
    name = "STM32: clean " .. project.project_name,
    cwd = project.root,
    components = task_utils.default_components(),
  })
end

function M.compile_db_task(project)
  local cfg = config_dir(project)

  if dev_utils.executable("compiledb") then
    return task_utils.task("compiledb make -C " .. vim.fn.shellescape(cfg), {
      name = "STM32: generate compile_commands.json (compiledb) " .. project.project_name,
      cwd = project.root,
      components = task_utils.quickfix_diagnostics_components(),
    })
  end

  if dev_utils.executable("bear") then
    return task_utils.task("bear -- make -C " .. vim.fn.shellescape(cfg), {
      name = "STM32: generate compile_commands.json (bear) " .. project.project_name,
      cwd = project.root,
      components = task_utils.quickfix_diagnostics_components(),
    })
  end

  return missing_tool_task({ "compiledb", "bear" }, "compile_commands.json generation")
end

function M.flash_task(project)
  local candidates = project.elf_candidates or {}
  local selected

  if #candidates == 0 then
    selected = vim.fn.input("Path to ELF: ", dev_utils.join(project.root, config_dir(project), ""), "file")
    if selected == "" then
      return nil
    end
  elseif #candidates == 1 then
    selected = candidates[1].path
  else
    local labels = vim.tbl_map(function(candidate)
      return candidate.label
    end, candidates)
    local idx = vim.fn.inputlist(vim.list_extend({ "Select ELF to flash:" }, labels))
    if idx < 1 or idx > #candidates then
      return nil
    end
    selected = candidates[idx].path
  end

  local command = "STM32_Programmer_CLI -c port=SWD -w "
    .. vim.fn.shellescape(selected)
    .. " -v -rst"

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
  local target_cfg = vim.fn.input("Target OpenOCD config (e.g. target/stm32f4x.cfg): ", "target/stm32f4x.cfg", "file")
  if target_cfg == "" then
    return nil
  end

  local command = "openocd -f interface/stlink.cfg -f " .. vim.fn.shellescape(target_cfg)

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
