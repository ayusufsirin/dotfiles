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
local STM32_TOOLS = { "STM32_Programmer_CLI", "ST-LINK_gdbserver", "openocd", "arm-none-eabi-gdb", "compiledb", "bear", "make", "node" }
local HEADLESS_APP = "org.eclipse.cdt.managedbuilder.core.headlessbuild"

local function notify(message, level)
  utils.notify(message, level, { title = "STM32 debug" })
end

local function load_local_overrides(root)
  local trusted = false
  local filenames = {
    ".nvim/stm32.lua",
    ".stm32-nvim.lua",
  }

  local ok_config, appdev_config = pcall(require, "appdev.config")
  if ok_config then
    local project_config = appdev_config.get().project_config or {}
    trusted = project_config.trusted_lua == true
    filenames = project_config.filenames or filenames
  end

  if not trusted then
    return nil
  end

  local candidates = {
  }
  for _, filename in ipairs(filenames) do
    candidates[#candidates + 1] = join(root, filename)
  end

  for _, path in ipairs(candidates) do
    if is_file(path) then
      local chunk, err = loadfile(path, "t", {})
      if not chunk then
        notify("Invalid local STM32 override file " .. path .. ": " .. tostring(err), vim.log.levels.ERROR)
        return nil
      end

      local ok, result = pcall(chunk)
      if not ok then
        notify("Failed to load local STM32 override file " .. path .. ": " .. tostring(result), vim.log.levels.ERROR)
        return nil
      end

      if type(result) == "table" then
        return result.stm32 or result
      end

      notify("Local STM32 override file " .. path .. " must return a table", vim.log.levels.WARN)
      return nil
    end
  end

  return nil
end

local function project_overrides(project)
  if not project then
    return {}
  end

  local overrides = load_local_overrides(project.root) or {}
  return {
    openocd_interface = overrides.openocd_interface or project.openocd_interface,
    openocd_target = overrides.openocd_target or project.openocd_target,
    svd_file = overrides.svd_file or project.svd_file,
  }
end

local function stm32_options()
  local ok, appdev_config = pcall(require, "appdev.config")
  if not ok then
    return {}
  end

  local adapter = (appdev_config.get().adapters or {}).stm32
  if type(adapter) == "table" then
    return adapter
  end

  return {}
end

local function cubeclt_options()
  local opts = stm32_options().cubeclt or {}
  return {
    install_dir = opts.install_dir or vim.env.STM32CUBECLT_DIR or vim.env.STM32CUBEIDE_DIR,
    workspace_dir = opts.workspace_dir or join(vim.fn.stdpath("cache"), "appdev-stm32-workspace"),
  }
end

local function cubeide_container_options()
  local opts = stm32_options().cubeide_container or {}
  return {
    enabled = opts.enabled == true,
    image = opts.image or "xanderhendriks/stm32cubeide:16.0",
    command = opts.command or "stm32cubeide",
    workspace_dir = opts.workspace_dir or "/tmp/appdev-stm32-workspace",
    project_mount_root = opts.project_mount_root or "/workspace",
    user = opts.user,
  }
end

local function executable_path(path)
  if path and path ~= "" and vim.fn.executable(path) == 1 then
    return normalize(path)
  end
end

local function first_executable(candidates)
  for _, candidate in ipairs(candidates or {}) do
    local resolved = executable_path(candidate)
    if resolved then
      return resolved
    end
  end
end

local function glob_executable(root, pattern)
  if not root or root == "" or not is_dir(root) then
    return nil
  end

  local matches = vim.fn.globpath(root, pattern, false, true)
  table.sort(matches)
  return first_executable(matches)
end

local function path_or_command(command)
  local from_path = vim.fn.exepath(command)
  if from_path and from_path ~= "" then
    return normalize(from_path)
  end
  return executable(command) and command or nil
end

local function resolve_cubeclt()
  local opts = cubeclt_options()
  local root = opts.install_dir and opts.install_dir ~= "" and normalize(opts.install_dir) or nil
  local tools = {
    install_dir = root,
    workspace_dir = normalize(opts.workspace_dir),
  }

  if root and is_dir(root) then
    tools.headless = first_executable({
      join(root, "headless-build.sh"),
      join(root, "headless-build"),
      join(root, "stm32cubeide"),
      join(root, "STM32CubeIDE"),
      join(root, "stm32cubeidec"),
    }) or glob_executable(root, "**/headless-build.sh")
      or glob_executable(root, "**/stm32cubeide")
      or glob_executable(root, "**/STM32CubeIDE")
      or glob_executable(root, "**/stm32cubeidec")

    tools.gdb = glob_executable(root, "**/arm-none-eabi-gdb")
    tools.gcc = glob_executable(root, "**/arm-none-eabi-gcc")
    tools.openocd = glob_executable(root, "**/openocd")
    tools.stlink_gdbserver = glob_executable(root, "**/ST-LINK_gdbserver")
      or glob_executable(root, "**/ST-LINK_gdbserver.sh")
    tools.programmer = glob_executable(root, "**/STM32_Programmer_CLI")
  end

  tools.gdb = tools.gdb or path_or_command("arm-none-eabi-gdb")
  tools.gcc = tools.gcc or path_or_command("arm-none-eabi-gcc")
  tools.openocd = tools.openocd or path_or_command("openocd")
  tools.stlink_gdbserver = tools.stlink_gdbserver or path_or_command("ST-LINK_gdbserver")
  tools.programmer = tools.programmer or path_or_command("STM32_Programmer_CLI")
  tools.make = path_or_command("make")
  tools.compiledb = path_or_command("compiledb")
  tools.bear = path_or_command("bear")
  tools.node = path_or_command("node")

  return tools
end

local function shell_with_env(command, project)
  local tools = resolve_cubeclt()
  local parts = {}
  if tools.gcc then
    parts[#parts + 1] = vim.fn.fnamemodify(tools.gcc, ":h")
  end
  if tools.gdb then
    parts[#parts + 1] = vim.fn.fnamemodify(tools.gdb, ":h")
  end
  if tools.openocd then
    parts[#parts + 1] = vim.fn.fnamemodify(tools.openocd, ":h")
  end
  if tools.stlink_gdbserver then
    parts[#parts + 1] = vim.fn.fnamemodify(tools.stlink_gdbserver, ":h")
  end
  if tools.programmer then
    parts[#parts + 1] = vim.fn.fnamemodify(tools.programmer, ":h")
  end

  local env_prefix = ""
  if #parts > 0 then
    env_prefix = "PATH=" .. vim.fn.shellescape(table.concat(parts, ":") .. ":$PATH") .. " "
  end

  local cwd = project and project.root or nil
  if cwd then
    return "cd " .. vim.fn.shellescape(cwd) .. " && " .. env_prefix .. command
  end
  return env_prefix .. command
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

local function read_text(path)
  if not is_file(path) then
    return nil
  end

  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok then
    return nil
  end

  return table.concat(lines, "\n")
end

local function xml_unescape(value)
  if not value then
    return nil
  end

  return value
    :gsub("&quot;", '"')
    :gsub("&apos;", "'")
    :gsub("&lt;", "<")
    :gsub("&gt;", ">")
    :gsub("&amp;", "&")
end

local function xml_attr(text, name)
  return xml_unescape(text and text:match(name .. '="([^"]*)"') or nil)
end

local function resolve_build_path(root, project_name_value, config_name, build_path)
  if not build_path or build_path == "" then
    return normalize(join(root, config_name))
  end

  local workspace_project = build_path:match("^%${workspace_loc:/([^}/]+)}")
  if workspace_project and workspace_project ~= project_name_value and workspace_project ~= "${ProjName}" then
    return normalize(join(root, config_name)),
      "Builder path references another Eclipse project: " .. build_path
  end

  local suffix = build_path:match("^%${workspace_loc:/[^}]+}[/\\]?(.*)$")
  if suffix and suffix ~= "" then
    return normalize(join(root, suffix))
  end

  return normalize(join(root, config_name))
end

local function parse_cproject_configs(root, project_name_value)
  local cproject = join(root, ".cproject")
  local text = read_text(cproject)
  if not text then
    return {}
  end

  local configs = {}
  local seen = {}
  for block in text:gmatch("<configuration%s+.-</configuration>") do
    local name = xml_attr(block, "name")
    if name and not seen[name] then
      seen[name] = true
      local build_path = xml_attr(block:match("<builder%s+.-/>") or "", "buildPath")
      local build_root, warning = resolve_build_path(root, project_name_value, name, build_path)
      local makefile = join(root, name, "Makefile")
      configs[#configs + 1] = {
        name = name,
        root = is_file(makefile) and normalize(join(root, name)) or build_root,
        makefile = is_file(makefile) and normalize(makefile) or nil,
        source = is_file(makefile) and "generated_makefile" or "managed_build",
        cproject = normalize(cproject),
        build_path = build_path,
        mcu = xml_unescape(block:match('target_mcu[^>]-value="([^"]+)"')),
        artifact_name = xml_attr(block, "artifactName"),
        warning = warning,
      }
    end
  end

  table.sort(configs, function(left, right)
    local left_order = vim.fn.index(BUILD_CONFIG_ORDER, left.name)
    local right_order = vim.fn.index(BUILD_CONFIG_ORDER, right.name)
    left_order = left_order >= 0 and left_order or 999
    right_order = right_order >= 0 and right_order or 999
    if left_order == right_order then
      return left.name < right.name
    end
    return left_order < right_order
  end)

  return configs
end

local function project_name(root, ioc)
  local eclipse_name = simple_project_name(join(root, ".project"))
  if eclipse_name then
    return eclipse_name
  end

  if ioc then
    return vim.fn.fnamemodify(ioc, ":t:r")
  end

  return vim.fn.fnamemodify(root, ":t")
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
  local seen = {}

  for _, name in ipairs(BUILD_CONFIG_ORDER) do
    local makefile = join(root, name, "Makefile")
    if is_file(makefile) then
      seen[name] = true
      configs[#configs + 1] = {
        name = name,
        root = normalize(join(root, name)),
        makefile = normalize(makefile),
        source = "generated_makefile",
      }
    end
  end

  local name = project_name(root, first_ioc(root))
  for _, config in ipairs(parse_cproject_configs(root, name)) do
    if not seen[config.name] then
      configs[#configs + 1] = config
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

local function config_summary(config)
  local source = config.source == "managed_build" and "managed" or "makefile"
  local marker = config.makefile and config.makefile or config.root
  return config.name .. " [" .. source .. ": " .. marker .. "]"
end

local function first_mcu(configs)
  for _, config in ipairs(configs or {}) do
    if config.mcu and config.mcu ~= "" then
      return config.mcu
    end
  end
end

local function infer_openocd_target(mcu)
  if not mcu then
    return nil
  end

  local family = mcu:upper():match("^STM32([A-Z]%d)")
  local targets = {
    F0 = "target/stm32f0x.cfg",
    F1 = "target/stm32f1x.cfg",
    F2 = "target/stm32f2x.cfg",
    F3 = "target/stm32f3x.cfg",
    F4 = "target/stm32f4x.cfg",
    F7 = "target/stm32f7x.cfg",
    G0 = "target/stm32g0x.cfg",
    G4 = "target/stm32g4x.cfg",
    H7 = "target/stm32h7x.cfg",
    L0 = "target/stm32l0.cfg",
    L1 = "target/stm32l1.cfg",
    L4 = "target/stm32l4x.cfg",
    U5 = "target/stm32u5x.cfg",
    WB = "target/stm32wbx.cfg",
    WL = "target/stm32wlx.cfg",
  }

  return targets[family]
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
    mcu = first_mcu(configs),
  }
  project.openocd_target = infer_openocd_target(project.mcu)

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

function M.run_overseer_template(name)
  local ok, overseer = pcall(require, "overseer")
  if not ok then
    notify("overseer.nvim is required for STM32 tasks", vim.log.levels.ERROR)
    return false
  end

  local project = M.current_project()
  overseer.run_task({
    name = name,
    search_params = {
      dir = project and project.root or vim.fn.getcwd(),
      filetype = vim.bo.filetype,
    },
  }, function(task)
    if task then
      overseer.open({ enter = false })
    end
  end)

  return true
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
    return config_summary(config)
  end, project.configs or {})
  local elf_paths = vim.tbl_map(function(candidate)
    return candidate.label
  end, project.elf_candidates or {})
  local warnings = {}
  for _, config in ipairs(project.configs or {}) do
    if config.warning then
      warnings[#warnings + 1] = config.name .. ": " .. config.warning
    end
  end
  local tools = resolve_cubeclt()
  local container = cubeide_container_options()

  return {
    "STM32CubeIDE project: " .. (project.project_name or vim.fn.fnamemodify(project.root, ":t")),
    "Root: " .. project.root,
    "MCU: " .. (project.mcu or "unknown"),
    "Build configs: " .. (#config_names > 0 and table.concat(config_names, ", ") or "none"),
    "Default config: " .. (project.default_config or "none"),
    "Makefile: " .. (project.makefile or "none"),
    "ELF candidates: " .. (#elf_paths > 0 and table.concat(elf_paths, ", ") or "none"),
    "IOC: " .. (project.ioc or "none"),
    "CubeCLT install: " .. (tools.install_dir or "not configured"),
    "CubeCLT headless: " .. (tools.headless or "not found"),
    "CubeCLT workspace: " .. (tools.workspace_dir or "not configured"),
    "Node: " .. (tools.node or "not found"),
    "CubeIDE container: " .. (container.enabled and container.image or "disabled"),
    "Warnings: " .. (#warnings > 0 and table.concat(warnings, "; ") or "none"),
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

local function cubeclt_headless_args(executable_path_value, workspace, project, config, mode)
  local spec = project.project_name .. "/" .. config.name
  local basename = vim.fn.fnamemodify(executable_path_value, ":t")
  local args = {
    executable_path_value,
    "-data",
    workspace,
  }

  if not basename:match("^headless%-build") then
    vim.list_extend(args, {
      "--launcher.suppressErrors",
      "-nosplash",
      "-application",
      HEADLESS_APP,
    })
  end

  vim.list_extend(args, {
    "-import",
    project.root,
    mode,
    spec,
  })

  return args
end

local function cubeclt_headless_command(project, config, mode)
  local tools = resolve_cubeclt()
  if tools.headless then
    local workspace = tools.workspace_dir or join(vim.fn.stdpath("cache"), "appdev-stm32-workspace")
    local args = cubeclt_headless_args(tools.headless, workspace, project, config, mode)
    local command = "mkdir -p " .. vim.fn.shellescape(workspace) .. " && " .. shell_join(args)
    return command, config
  end

  local container = cubeide_container_options()
  if container.enabled then
    local project_mount = join(container.project_mount_root, vim.fn.fnamemodify(project.root, ":t"))
    local workspace = container.workspace_dir
    local docker_args = {
      "docker",
      "run",
      "--rm",
      "-e",
      "HOME=/tmp",
    }

    if container.user and container.user ~= "" then
      vim.list_extend(docker_args, { "-u", container.user })
    end

    vim.list_extend(docker_args, {
      "-v",
      project.root .. ":" .. project_mount,
      "-w",
      container.project_mount_root,
      container.image,
    })

    local headless_args = cubeclt_headless_args(container.command, workspace, {
      root = project_mount,
      project_name = project.project_name,
    }, config, mode)
    vim.list_extend(docker_args, headless_args)

    return shell_join(docker_args), config
  end

  return nil,
    "STM32CubeIDE headless managed builder not found. Configure adapters.stm32.cubeide_container.enabled=true with a CubeIDE Docker image, install full STM32CubeIDE/headless builder, or generate Makefile/CMake output.",
    config
end

function M.cubeclt_tools()
  return resolve_cubeclt()
end

function M.refresh_managed_build(project, config_name)
  if not project then
    return config_error(project, config_name)
  end

  local config = selected_config(project, config_name)
  if not config then
    return config_error(project, config_name)
  end

  local tools = resolve_cubeclt()
  local container = cubeide_container_options()
  if not tools.headless and not container.enabled then
    return nil,
      "STM32CubeIDE headless managed builder not found. Configure adapters.stm32.cubeide_container.enabled=true with a CubeIDE Docker image, install full STM32CubeIDE/headless builder, or generate Makefile/CMake output.",
      config
  end

  if not tools.headless then
    return cubeclt_headless_command(project, config, "-cleanBuild")
  end

  local workspace = tools.workspace_dir or join(vim.fn.stdpath("cache"), "appdev-stm32-workspace")
  local basename = vim.fn.fnamemodify(tools.headless, ":t")
  local args = { tools.headless }
  if not basename:match("^headless%-build") then
    vim.list_extend(args, {
      "--launcher.suppressErrors",
      "-nosplash",
      "-application",
      HEADLESS_APP,
    })
  end
  vim.list_extend(args, {
    "-data",
    workspace,
    "-import",
    project.root,
  })

  return "mkdir -p " .. vim.fn.shellescape(workspace) .. " && " .. shell_join(args), config
end

function M.build_current_config(project, config_name)
  if not project then
    return config_error(project, config_name)
  end

  local config = selected_config(project, config_name)
  if not config then
    return config_error(project, config_name)
  end

  if not config.makefile then
    return cubeclt_headless_command(project, config, "-build")
  end

  local command = shell_with_env("make -j" .. make_jobs_flag() .. " all -C " .. vim.fn.shellescape(config.root), project)
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

  if not config.makefile then
    return cubeclt_headless_command(project, config, "-cleanBuild")
  end

  local command = shell_with_env("make clean -C " .. vim.fn.shellescape(config.root), project)
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

  if not config.makefile then
    return nil,
      "compile_commands.json generation requires a generated Makefile. Run STM32: build first; if CubeCLT does not generate a Makefile, use STM32CubeIDE/CubeCLT export settings or Bear against a real build.",
      config
  end

  if executable("compiledb") then
    local command = shell_with_env("compiledb make -C " .. vim.fn.shellescape(config.root), project)
    return command, config
  end

  if executable("bear") then
    local command = shell_with_env("bear -- make -j" .. make_jobs_flag() .. " all -C " .. vim.fn.shellescape(config.root), project)
    return command, config, "note: Bear may require a clean build"
  end

  return nil,
    "No compile database tool found. Install 'compiledb' (recommended) or 'bear', and ensure it is on PATH.",
    config
end

-- Flash / erase / OpenOCD command builders -----------------------------------------

local function pick_elf(project, elf_path)
  if elf_path then
    if is_file(elf_path) then
      return normalize(elf_path)
    end
    return nil
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

  local tools = resolve_cubeclt()
  if not tools.programmer then
    return nil,
      "STM32_Programmer_CLI is not on PATH. Install STM32CubeProgrammer (part of STM32CubeCLT) and add it to PATH.",
      project
  end

  local selected = pick_elf(project, elf_path)
  if not selected then
    local reason = elf_path and ("ELF not found: " .. elf_path) or "No ELF candidate found for the selected build config"
    return nil, reason, project
  end

  local command = vim.fn.shellescape(tools.programmer) .. " -c port=SWD -w "
    .. vim.fn.shellescape(selected)
    .. " -v -rst"
  return command, selected, project
end

function M.reset_run(project, opts)
  opts = opts or {}
  if not project then
    return nil, "No STM32CubeIDE project found"
  end

  local tools = resolve_cubeclt()
  if tools.openocd then
    local command, err = M.start_openocd(project, opts)
    if not command then
      return nil, err, project
    end

    return command .. " -c " .. vim.fn.shellescape("init; reset run; shutdown"), project
  end

  if tools.programmer then
    return vim.fn.shellescape(tools.programmer) .. " -c port=SWD -rst", project
  end

  return nil, "OpenOCD or STM32_Programmer_CLI is required to reset/run the target", project
end

function M.erase_chip(confirmed)
  if not confirmed then
    return nil,
      "Chip erase requires explicit confirmation. Pass confirmed=true to build the erase command, then review before executing."
  end

  local tools = resolve_cubeclt()
  if not tools.programmer then
    return nil,
      "STM32_Programmer_CLI is not on PATH. Install STM32CubeProgrammer (part of STM32CubeCLT) and add it to PATH."
  end

  return vim.fn.shellescape(tools.programmer) .. " -c port=SWD -e all"
end

function M.start_openocd(project, opts)
  opts = opts or {}

  local tools = resolve_cubeclt()
  if not tools.openocd then
    return nil,
      "openocd is not on PATH. Install OpenOCD and add it to PATH for debug-server tasks.",
      "interface/stlink.cfg"
  end

  local overrides = project and project_overrides(project) or {}
  local interface = opts.interface or overrides.openocd_interface or (project and project.openocd_interface) or "interface/stlink.cfg"
  local target = opts.target or overrides.openocd_target or (project and project.openocd_target) or nil

  if not target then
    return nil,
      "OpenOCD target config is not set. Pass opts.target (e.g. 'stm32f4x.cfg'), set project.openocd_target, or use a local override file.",
      interface
  end

  local target_path = target
  if not target_path:match("^target/") and not target_path:match("^interface/") then
    target_path = "target/" .. target_path
  end

  local command = vim.fn.shellescape(tools.openocd) .. " -f "
    .. vim.fn.shellescape(interface)
    .. " -f "
    .. vim.fn.shellescape(target_path)
  return command, interface, target_path
end

-- DAP configuration -----------------------------------------------------------------

function M.cortex_configurations(opts)
  opts = opts or {}

  local project = opts.project
  if not project and opts.path then
    project = M.current_project(opts.path)
  end
  if not project then
    project = M.current_project()
  end
  if not project then
    return nil, "No STM32CubeIDE project found"
  end

  local overrides = project_overrides(project)
  local tools = resolve_cubeclt()
  if not tools.node then
    return nil, "node is required by cortex-debug. Install Node.js or add it to PATH.", project
  end
  local use_openocd = tools.openocd or not tools.stlink_gdbserver
  local interface = opts.interface or overrides.openocd_interface or "interface/stlink.cfg"
  local target = opts.target or overrides.openocd_target
  if use_openocd and not target then
    return nil, "OpenOCD target config is not set. Pass opts.target (e.g. 'stm32f4x.cfg'), set project.openocd_target, or use a local override file.", project
  end

  local target_path = target
  if target_path and not target_path:match("^target/") and not target_path:match("^interface/") then
    target_path = "target/" .. target_path
  end

  local elf
  if opts.elf_path then
    if is_file(opts.elf_path) then
      elf = normalize(opts.elf_path)
    else
      return nil, "ELF not found: " .. opts.elf_path, project
    end
  else
    local candidates = project.elf_candidates or M.elf_candidates(project)
    if #candidates == 1 then
      elf = candidates[1].path
    elseif #candidates > 1 then
      return nil, "Multiple ELF candidates found; pass opts.elf_path to select one", project
    else
      return nil, "No ELF candidate found for the selected build config", project
    end
  end

  local svd_file = opts.svd_file or overrides.svd_file
  local cwd = opts.cwd or project.root

  local config = {
    name = "STM32 Cortex-M: " .. project.project_name,
    type = "cortex-debug",
    request = "launch",
    gdbPath = tools.gdb or "arm-none-eabi-gdb",
    executable = elf,
    cwd = cwd,
    runToEntryPoint = "main",
  }

  if tools.openocd then
    config.servertype = "openocd"
    config.serverpath = tools.openocd
    config.configFiles = { interface, target_path }
  elseif tools.stlink_gdbserver then
    config.servertype = "stlink"
    config.serverpath = tools.stlink_gdbserver
    if project.mcu then
      config.device = project.mcu
    end
  else
    config.servertype = "openocd"
    config.serverpath = "openocd"
    config.configFiles = { interface, target_path }
  end

  if svd_file and svd_file ~= "" then
    config.svdFile = normalize(svd_file)
  end

  return { config }, project
end

function M.launch_debug(opts)
  opts = opts or {}
  local dap = require("dap")

  local project = opts.project
  if not project and opts.path then
    project = M.current_project(opts.path)
  end
  if not project then
    project = M.current_project()
  end
  if not project then
    notify("No STM32CubeIDE project found", vim.log.levels.ERROR)
    return dap.ABORT
  end

  local overrides = project_overrides(project)
  local target = opts.target or overrides.openocd_target
  if not target then
    target = vim.fn.input("OpenOCD target config (e.g. target/stm32f4x.cfg): ", "target/stm32f4x.cfg", "file")
    if target == "" then
      notify("STM32 debug cancelled: no OpenOCD target config selected", vim.log.levels.INFO)
      return dap.ABORT
    end
  end

  local elf = pick_elf(project, opts.elf_path)
  if not elf then
    notify("No ELF candidate found for the selected build config", vim.log.levels.ERROR)
    return dap.ABORT
  end

  local configs, err = M.cortex_configurations(vim.tbl_extend("force", opts, {
    project = project,
    target = target,
    elf_path = elf,
  }))

  if not configs then
    notify(err or "Could not build STM32 debug configuration", vim.log.levels.ERROR)
    return dap.ABORT
  end

  dap.run(configs[1])
  return configs[1]
end

-- Environment inspection -----------------------------------------------------------

local function tool_status_lines()
  local status = command_availability(STM32_TOOLS)
  local tools = resolve_cubeclt()
  local lines = {
    "Tool availability:",
    "  Available: " .. (#status.available > 0 and table.concat(status.available, ", ") or "none"),
    "  Missing: " .. (#status.missing > 0 and table.concat(status.missing, ", ") or "none"),
    "  Resolved CubeCLT tools:",
    "    headless: " .. (tools.headless or "not found"),
    "    gcc: " .. (tools.gcc or "not found"),
    "    make: " .. (tools.make or "not found"),
    "    gdb: " .. (tools.gdb or "not found"),
    "    openocd: " .. (tools.openocd or "not found"),
    "    stlink_gdbserver: " .. (tools.stlink_gdbserver or "not found"),
    "    programmer: " .. (tools.programmer or "not found"),
    "    compiledb: " .. (tools.compiledb or "not found"),
    "    bear: " .. (tools.bear or "not found"),
    "    node: " .. (tools.node or "not found"),
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
  local tools = resolve_cubeclt()

  if not project then
    steps[#steps + 1] = "Open a file inside an STM32CubeIDE project to enable STM32 commands."
    return steps
  end

  steps[#steps + 1] = "Build: :AppDevBuild"
  steps[#steps + 1] = "Run/reset target: :AppDevRun"
  steps[#steps + 1] = "Clean: :AppDevAction clean"
  if project.default_config and not project.makefile then
    if tools.headless then
      steps[#steps + 1] = "Managed build: no generated Makefile found; AppDev will use the configured CubeIDE headless builder."
    elseif cubeide_container_options().enabled then
      steps[#steps + 1] = "Managed build: no generated Makefile found; AppDev will use the configured CubeIDE Docker image."
    else
      steps[#steps + 1] = "Managed build: no generated Makefile found, and configured CubeCLT has no CubeIDE headless builder."
    end
  end

  if executable("compiledb") or executable("bear") then
    steps[#steps + 1] = "Generate compile_commands.json: :lua require('config.stm32_debug').generate_compile_commands(project)"
  else
    steps[#steps + 1] = "Install 'compiledb' or 'bear' to generate compile_commands.json for clangd."
  end

  if tools.programmer then
    steps[#steps + 1] = "Flash: :lua require('config.stm32_debug').flash_elf(project)"
    steps[#steps + 1] = "Erase: :lua require('config.stm32_debug').erase_chip(true) -- review before executing"
  else
    steps[#steps + 1] = "Install STM32CubeProgrammer / STM32CubeCLT and add STM32_Programmer_CLI to PATH for flash/erase."
  end

  if tools.openocd then
    steps[#steps + 1] = "OpenOCD server: :lua require('config.stm32_debug').start_openocd(project, {target='stm32f4x.cfg'})"
  elseif tools.stlink_gdbserver then
    steps[#steps + 1] = "DAP debug: CubeCLT ST-LINK GDB server is available; use :AppDevDebug after selecting/building an ELF."
  else
    steps[#steps + 1] = "Install OpenOCD or STM32CubeCLT ST-LINK GDB server for debug-server tasks."
  end

  if not tools.gdb then
    steps[#steps + 1] = "Install arm-none-eabi-gdb (part of STM32CubeCLT or ARM GCC) for DAP debugging."
  end
  if not tools.node then
    steps[#steps + 1] = "Install Node.js or add 'node' to PATH for cortex-debug / nvim-dap-cortex-debug."
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
