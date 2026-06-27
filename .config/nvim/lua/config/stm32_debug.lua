local utils = require("config.dev_utils")

local M = {}

local join = utils.join
local normalize = utils.normalize
local is_file = utils.is_file
local is_dir = utils.is_dir
local shell_join = utils.shell_join
local executable = utils.executable
local command_availability = utils.command_availability

local BUILD_CONFIG_ORDER = { "Debug", "Release" }
local STM32_TOOLS = { "STM32_Programmer_CLI", "openocd", "arm-none-eabi-gdb", "compiledb", "bear", "make" }

local function notify(message, level)
  utils.notify(message, level, { title = "STM32 debug" })
end

local function sorted_paths(paths)
  paths = paths or {}
  table.sort(paths, function(left, right)
    return left < right
  end)
  return paths
end

local function first_ioc(root)
  local matches = sorted_paths(vim.fn.globpath(root, "*.ioc", false, true))
  if #matches == 0 then
    return nil
  end

  return normalize(matches[1])
end

local function simple_project_name(project_file)
  if not is_file(project_file) then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, project_file)
  if not ok then
    return nil
  end

  local text = table.concat(lines, "\n")
  local name = text:match("<name>%s*([^<%s][^<]-)%s*</name>")
  if not name or name:find("[<>]") then
    return nil
  end

  return vim.trim(name)
end

local function project_name(root, ioc)
  if ioc then
    return vim.fn.fnamemodify(ioc, ":t:r")
  end

  return simple_project_name(join(root, ".project")) or vim.fn.fnamemodify(root, ":t")
end

local function marker_paths(root)
  local markers = {}
  local ioc = first_ioc(root)
  if ioc then
    markers[#markers + 1] = ioc
  end

  for _, marker in ipairs({ ".project", ".cproject", ".mxproject" }) do
    local path = join(root, marker)
    if is_file(path) then
      markers[#markers + 1] = normalize(path)
    end
  end

  for _, config in ipairs(BUILD_CONFIG_ORDER) do
    local makefile = join(root, config, "Makefile")
    if is_file(makefile) then
      markers[#markers + 1] = normalize(makefile)
    end
  end

  return markers, ioc
end

local function discover_build_configs(root)
  local configs = {}

  for _, name in ipairs(BUILD_CONFIG_ORDER) do
    local makefile = join(root, name, "Makefile")
    if is_file(makefile) then
      configs[#configs + 1] = {
        name = name,
        root = normalize(join(root, name)),
        makefile = normalize(makefile),
      }
    end
  end

  return configs
end

local function config_by_name(project, name)
  if not project then
    return nil
  end

  for _, config in ipairs(project.configs or {}) do
    if config.name == name then
      return config
    end
  end
end

local function default_config_name(configs)
  for _, preferred in ipairs(BUILD_CONFIG_ORDER) do
    for _, config in ipairs(configs or {}) do
      if config.name == preferred then
        return preferred
      end
    end
  end

  return configs and configs[1] and configs[1].name or nil
end

local function elf_label(root, path)
  local escaped_root = vim.pesc(root)
  return path:gsub("^" .. escaped_root .. "/", "")
end

local function project_marker(dir)
  local markers, ioc = marker_paths(dir)
  if #markers == 0 then
    return nil
  end

  local root = normalize(dir)
  local configs = discover_build_configs(root)
  local default_name = default_config_name(configs)
  local default = config_by_name({ configs = configs }, default_name)
  local project = {
    root = root,
    configs = configs,
    default_config = default_name,
    makefile = default and default.makefile or nil,
    ioc = ioc,
    project_name = project_name(root, ioc),
    markers = markers,
  }

  project.elf_candidates = M.elf_candidates(project, default_name)
  project.inspection = table.concat(M.inspect_lines(project), "\n")

  return project
end

function M.current_project(path)
  return utils.find_upward(path, project_marker)
end

function M.require_project(path)
  local project = M.current_project(path)
  if project then
    return project
  end

  notify("No STM32CubeIDE project found from the current file or working directory")
end

function M.build_configs(project)
  return project and project.configs or {}
end

function M.default_config(project)
  return project and project.default_config or nil
end

function M.elf_candidates(project, config)
  if not project then
    return {}
  end

  local selected = config_by_name(project, config or project.default_config)
  if not selected or not is_dir(selected.root) then
    return {}
  end

  local paths = sorted_paths(vim.fn.globpath(selected.root, "**/*.elf", false, true))
  local candidates = {}
  for _, path in ipairs(paths) do
    if is_file(path) then
      local normalized = normalize(path)
      candidates[#candidates + 1] = {
        path = normalized,
        config = selected.name,
        label = elf_label(project.root, normalized),
      }
    end
  end

  return candidates
end

function M.inspect_lines(project)
  if not project then
    return { "STM32CubeIDE project: not found" }
  end

  local config_names = vim.tbl_map(function(config)
    return config.name
  end, project.configs or {})
  local elf_paths = vim.tbl_map(function(candidate)
    return candidate.label
  end, project.elf_candidates or {})

  return {
    "STM32CubeIDE project: " .. (project.project_name or vim.fn.fnamemodify(project.root, ":t")),
    "Root: " .. project.root,
    "Build configs: " .. (#config_names > 0 and table.concat(config_names, ", ") or "none"),
    "Default config: " .. (project.default_config or "none"),
    "Makefile: " .. (project.makefile or "none"),
    "ELF candidates: " .. (#elf_paths > 0 and table.concat(elf_paths, ", ") or "none"),
    "IOC: " .. (project.ioc or "none"),
  }
end

-- Build / config selection helpers --------------------------------------------------

local function selected_config(project, config_name)
  if not project then
    return nil
  end

  return config_by_name(project, config_name or project.default_config) or project.configs[1]
end

local function config_error(project, config_name)
  if not project then
    return nil, "No STM32CubeIDE project found"
  end

  if config_name then
    return nil, "Build config '" .. config_name .. "' not found in project"
  end

  return nil, "No build config available in project"
end

local function make_jobs_flag()
  -- Portable shell expression: use nproc when available, otherwise a safe default.
  return '"$(nproc 2>/dev/null || echo 4)"'
end

function M.build_current_config(project, config_name)
  if not project then
    return config_error(project, config_name)
  end

  local config = selected_config(project, config_name)
  if not config then
    return config_error(project, config_name)
  end

  local command = "make -j" .. make_jobs_flag() .. " all -C " .. vim.fn.shellescape(config.root)
  return command, config
end

function M.clean_current_config(project, config_name)
  if not project then
    return config_error(project, config_name)
  end

  local config = selected_config(project, config_name)
  if not config then
    return config_error(project, config_name)
  end

  local command = "make clean -C " .. vim.fn.shellescape(config.root)
  return command, config
end

function M.generate_compile_commands(project, config_name)
  if not project then
    return config_error(project, config_name)
  end

  local config = selected_config(project, config_name)
  if not config then
    return config_error(project, config_name)
  end

  if executable("compiledb") then
    local command = "compiledb make -C " .. vim.fn.shellescape(config.root)
    return command, config
  end

  if executable("bear") then
    local command = "bear -- make -j" .. make_jobs_flag() .. " all -C " .. vim.fn.shellescape(config.root)
    return command, config, "note: Bear may require a clean build"
  end

  return nil,
    "No compile database tool found. Install 'compiledb' (recommended) or 'bear', and ensure it is on PATH.",
    config
end

-- Flash / erase / OpenOCD command builders -----------------------------------------

local function pick_elf(project, elf_path)
  if elf_path then
    return normalize(elf_path)
  end

  local candidates = project.elf_candidates or M.elf_candidates(project)
  if #candidates == 1 then
    return candidates[1].path
  end

  if #candidates > 1 then
    local labels = vim.tbl_map(function(candidate)
      return candidate.label
    end, candidates)
    local choice = vim.fn.inputlist(vim.list_extend({ "Select ELF to flash:" }, labels))
    if choice >= 1 and choice <= #candidates then
      return candidates[choice].path
    end
    return nil
  end

  return nil
end

function M.flash_elf(project, elf_path)
  if not project then
    return nil, "No STM32CubeIDE project found"
  end

  if not executable("STM32_Programmer_CLI") then
    return nil,
      "STM32_Programmer_CLI is not on PATH. Install STM32CubeProgrammer (part of STM32CubeCLT) and add it to PATH.",
      project
  end

  local selected = pick_elf(project, elf_path)
  if not selected then
    local reason = elf_path and ("ELF not found: " .. elf_path) or "No ELF candidate found for the selected build config"
    return nil, reason, project
  end

  local command = "STM32_Programmer_CLI -c port=SWD -w "
    .. vim.fn.shellescape(selected)
    .. " -v -rst"
  return command, selected, project
end

function M.erase_chip(confirmed)
  if not confirmed then
    return nil,
      "Chip erase requires explicit confirmation. Pass confirmed=true to build the erase command, then review before executing."
  end

  if not executable("STM32_Programmer_CLI") then
    return nil,
      "STM32_Programmer_CLI is not on PATH. Install STM32CubeProgrammer (part of STM32CubeCLT) and add it to PATH."
  end

  return "STM32_Programmer_CLI -c port=SWD -e all"
end

function M.start_openocd(project, opts)
  opts = opts or {}

  if not executable("openocd") then
    return nil,
      "openocd is not on PATH. Install OpenOCD and add it to PATH for debug-server tasks.",
      "interface/stlink.cfg"
  end

  local interface = opts.interface or (project and project.openocd_interface) or "interface/stlink.cfg"
  local target = opts.target or (project and project.openocd_target) or nil

  if not target then
    return nil,
      "OpenOCD target config is not set. Pass opts.target (e.g. 'stm32f4x.cfg') or set project.openocd_target.",
      interface
  end

  local target_path = target
  if not target_path:match("^target/") and not target_path:match("^interface/") then
    target_path = "target/" .. target_path
  end

  local command = "openocd -f "
    .. vim.fn.shellescape(interface)
    .. " -f "
    .. vim.fn.shellescape(target_path)
  return command, interface, target_path
end

-- Environment inspection -----------------------------------------------------------

local function tool_status_lines()
  local status = command_availability(STM32_TOOLS)
  local lines = {
    "Tool availability:",
    "  Available: " .. (#status.available > 0 and table.concat(status.available, ", ") or "none"),
    "  Missing: " .. (#status.missing > 0 and table.concat(status.missing, ", ") or "none"),
  }

  return lines, status
end

local function openocd_choice_lines(project)
  local interface = project and project.openocd_interface or "interface/stlink.cfg"
  local target = project and project.openocd_target or nil
  return {
    "OpenOCD interface: " .. interface,
    "OpenOCD target: " .. (target or "<not set; pass opts.target or set project.openocd_target>"),
  }
end

local function suggested_steps_lines(project, status)
  local steps = {}

  if not project then
    steps[#steps + 1] = "Open a file inside an STM32CubeIDE project to enable STM32 commands."
    return steps
  end

  steps[#steps + 1] = "Build: :lua require('config.stm32_debug').build_current_config(project)"
  steps[#steps + 1] = "Clean: :lua require('config.stm32_debug').clean_current_config(project)"

  if executable("compiledb") or executable("bear") then
    steps[#steps + 1] = "Generate compile_commands.json: :lua require('config.stm32_debug').generate_compile_commands(project)"
  else
    steps[#steps + 1] = "Install 'compiledb' or 'bear' to generate compile_commands.json for clangd."
  end

  if executable("STM32_Programmer_CLI") then
    steps[#steps + 1] = "Flash: :lua require('config.stm32_debug').flash_elf(project)"
    steps[#steps + 1] = "Erase: :lua require('config.stm32_debug').erase_chip(true) -- review before executing"
  else
    steps[#steps + 1] = "Install STM32CubeProgrammer / STM32CubeCLT and add STM32_Programmer_CLI to PATH for flash/erase."
  end

  if executable("openocd") then
    steps[#steps + 1] = "OpenOCD server: :lua require('config.stm32_debug').start_openocd(project, {target='stm32f4x.cfg'})"
  else
    steps[#steps + 1] = "Install OpenOCD and add it to PATH for debug-server tasks."
  end

  if not executable("arm-none-eabi-gdb") then
    steps[#steps + 1] = "Install arm-none-eabi-gdb (part of STM32CubeCLT or ARM GCC) for DAP debugging."
  end

  return steps
end

function M.inspect_environment_lines(path_or_project)
  local project
  if type(path_or_project) == "table" and path_or_project.root then
    project = path_or_project
  else
    project = M.current_project(path_or_project)
  end

  local lines = {
    "STM32 debug environment",
    "",
  }

  if project then
    vim.list_extend(lines, M.inspect_lines(project))
  else
    lines[#lines + 1] = "STM32CubeIDE project: not found"
  end

  lines[#lines + 1] = ""
  local status_lines, status = tool_status_lines()
  vim.list_extend(lines, status_lines)

  lines[#lines + 1] = ""
  vim.list_extend(lines, openocd_choice_lines(project))

  lines[#lines + 1] = ""
  lines[#lines + 1] = "Suggested next steps:"
  for _, step in ipairs(suggested_steps_lines(project, status)) do
    lines[#lines + 1] = "  - " .. step
  end

  return lines, project, status
end

function M.inspect_environment(path_or_project)
  local lines = M.inspect_environment_lines(path_or_project)

  vim.cmd("botright new")
  local bufnr = vim.api.nvim_get_current_buf()
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "sh"
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  return lines
end

return M
