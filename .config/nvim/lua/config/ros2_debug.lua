local M = {}

local env_cache = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.WARN, { title = "ROS2 debug" })
end

local function join(...)
  if vim.fs and vim.fs.joinpath then
    return vim.fs.joinpath(...)
  end

  return table.concat(vim.tbl_filter(function(part)
    return part ~= nil and part ~= ""
  end, { ... }), "/"):gsub("//+", "/")
end

local function dirname(path)
  if vim.fs and vim.fs.dirname then
    return vim.fs.dirname(path)
  end

  return vim.fn.fnamemodify(path, ":h")
end

local function normalize(path)
  if vim.fs and vim.fs.normalize then
    return vim.fs.normalize(path)
  end

  return vim.fn.fnamemodify(path, ":p")
end

local function is_file(path)
  return path and vim.fn.filereadable(path) == 1
end

local function is_dir(path)
  return path and vim.fn.isdirectory(path) == 1
end

local function start_path(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if path == "" then
    path = vim.fn.getcwd()
  end

  path = normalize(path)
  if is_file(path) then
    path = dirname(path)
  end

  return path
end

local function workspace_marker(dir)
  local setup = join(dir, "install", "setup.bash")
  local local_setup = join(dir, "install", "local_setup.bash")

  if not is_file(setup) then
    setup = local_setup
  end

  if is_file(setup) then
    return {
      root = dir,
      setup = setup,
    }
  end

  if is_dir(join(dir, "src")) and (is_dir(join(dir, "build")) or is_file(join(dir, "compile_commands.json"))) then
    return {
      root = dir,
      setup = nil,
    }
  end
end

local function ros_underlay_setup()
  local distro = vim.env.ROS_DISTRO
  if distro and distro ~= "" then
    local setup = join("/opt/ros", distro, "setup.bash")
    if is_file(setup) then
      return setup
    end
  end

  local candidates = vim.fn.glob("/opt/ros/*/setup.bash", false, true)
  if #candidates == 1 then
    return candidates[1]
  end
end

local function parse_executable(root, path)
  local escaped_root = vim.pesc(root)
  local rel = path:gsub("^" .. escaped_root .. "/", "")
  local install_package, lib_package, executable = rel:match("^install/([^/]+)/lib/([^/]+)/(.+)$")
  local package_name = lib_package or install_package or "unknown"

  return {
    package = package_name,
    name = executable or vim.fn.fnamemodify(path, ":t"),
    path = path,
    label = string.format("%s/%s", package_name, executable or vim.fn.fnamemodify(path, ":t")),
  }
end

local function prompt_args(prompt)
  local input = vim.fn.input(prompt .. " args: ")
  if input == "" then
    return {}
  end

  return vim.fn.split(input)
end

local function shell_join(args)
  return table.concat(vim.tbl_map(vim.fn.shellescape, args or {}), " ")
end

local function package_name(package_xml)
  local ok, lines = pcall(vim.fn.readfile, package_xml)
  if not ok then
    return nil
  end

  local text = table.concat(lines, "\n")
  return text:match("<name>%s*([^<%s]+)%s*</name>")
end

local function setup_source_parts(workspace, include_workspace)
  local parts = {}
  local underlay = ros_underlay_setup()
  if underlay then
    parts[#parts + 1] = "source " .. vim.fn.shellescape(underlay) .. " >/dev/null 2>&1"
  end

  if include_workspace and workspace and workspace.setup then
    parts[#parts + 1] = "source " .. vim.fn.shellescape(workspace.setup) .. " >/dev/null 2>&1"
  end

  return parts
end

local function env_cache_key(workspace)
  if not workspace or not workspace.setup then
    return nil
  end

  local uv = vim.uv or vim.loop
  local stat = uv and uv.fs_stat(workspace.setup) or nil
  local mtime = stat and stat.mtime and stat.mtime.sec or 0
  return workspace.setup .. ":" .. mtime .. ":" .. (ros_underlay_setup() or "")
end

function M.current_workspace(path)
  local dir = start_path(path)

  while dir and dir ~= "" do
    local marker = workspace_marker(dir)
    if marker then
      return marker
    end

    local parent = dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
end

function M.require_workspace(path)
  local workspace = M.current_workspace(path)
  if workspace then
    return workspace
  end

  notify("No ROS2 workspace found from the current file or working directory")
end

function M.require_sourced_workspace(path)
  local workspace = M.require_workspace(path)
  if not workspace then
    return nil
  end

  if workspace.setup then
    return workspace
  end

  notify("Workspace has no install setup file. Build it with colcon first.")
end

function M.workspace_env(workspace)
  workspace = workspace or M.require_sourced_workspace()
  if not workspace or not workspace.setup then
    return nil
  end

  local key = env_cache_key(workspace)
  if key and env_cache[key] then
    return vim.deepcopy(env_cache[key])
  end

  local source_parts = setup_source_parts(workspace, true)
  source_parts[#source_parts + 1] = "env"

  local command = table.concat(source_parts, " && ")
  local lines = vim.fn.systemlist({ "bash", "-lc", command })
  if vim.v.shell_error ~= 0 then
    notify("Failed to source " .. workspace.setup .. "\n" .. table.concat(lines, "\n"), vim.log.levels.ERROR)
    return nil
  end

  local env = {}
  for _, line in ipairs(lines) do
    local name, value = line:match("^([^=]+)=(.*)$")
    if name and value then
      env[name] = value
    end
  end
  env.PYTHONUNBUFFERED = "1"

  if key then
    env_cache = {
      [key] = env,
    }
  end

  return vim.deepcopy(env)
end

function M.workspace_env_or_empty()
  local workspace = M.current_workspace()
  if not workspace or not workspace.setup then
    return {}
  end

  return M.workspace_env(workspace) or {}
end

function M.workspace_root_or_cwd()
  local workspace = M.current_workspace()
  return workspace and workspace.root or vim.fn.getcwd()
end

function M.current_package(path)
  local workspace = M.current_workspace(path)
  local dir = start_path(path)

  while dir and dir ~= "" do
    local package_xml = join(dir, "package.xml")
    if is_file(package_xml) then
      local name = package_name(package_xml)
      if name then
        return {
          name = name,
          root = dir,
          package_xml = package_xml,
          workspace = workspace,
        }
      end
    end

    if workspace and dir == workspace.root then
      break
    end

    local parent = dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
end

function M.source_command(workspace, include_workspace)
  local parts = setup_source_parts(workspace, include_workspace)
  return table.concat(parts, " && ")
end

local function build_args(package)
  local args = {
    "colcon",
    "build",
  }

  if package and package.name then
    args[#args + 1] = "--packages-up-to"
    args[#args + 1] = package.name
  end

  vim.list_extend(args, {
    "--symlink-install",
    "--cmake-args",
    "-DCMAKE_BUILD_TYPE=Debug",
    "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON",
  })

  return args
end

function M.workspace_build_command(workspace)
  workspace = workspace or M.require_workspace()
  if not workspace then
    return nil
  end

  local command = shell_join(build_args(nil))
  local source = M.source_command(workspace, true)
  if source ~= "" then
    command = source .. " && " .. command
  end

  return command, workspace
end

function M.build_command(path)
  local workspace = M.require_workspace(path)
  if not workspace then
    return nil
  end

  local package = M.current_package(path)
  local command = shell_join(build_args(package))
  local source = M.source_command(workspace, true)
  if source ~= "" then
    command = source .. " && " .. command
  end

  return command, workspace, package
end

function M.run_overseer_template(name)
  local ok, overseer = pcall(require, "overseer")
  if not ok then
    return false
  end

  local workspace = M.current_workspace()
  overseer.run_task({
    name = name,
    search_params = {
      dir = workspace and workspace.root or vim.fn.getcwd(),
      filetype = vim.bo.filetype,
    },
  }, function(task)
    if task then
      overseer.open({ enter = false })
    end
  end)

  return true
end

function M.build_current_package()
  if not M.run_overseer_template("ROS2: build current package") then
    notify("overseer.nvim is required for ROS2 build tasks", vim.log.levels.ERROR)
  end
end

function M.ros_executables(workspace)
  workspace = workspace or M.require_workspace()
  if not workspace then
    return {}
  end

  local install = join(workspace.root, "install")
  if not is_dir(install) then
    notify("No install directory found. Build the workspace before debugging installed nodes.")
    return {}
  end

  local paths = vim.fn.globpath(install, "*/lib/*/*", false, true)
  local executables = {}
  for _, path in ipairs(paths) do
    if is_file(path) and vim.fn.executable(path) == 1 then
      executables[#executables + 1] = parse_executable(workspace.root, normalize(path))
    end
  end

  table.sort(executables, function(left, right)
    return left.label < right.label
  end)

  return executables
end

function M.input_executable_path()
  local workspace = M.current_workspace()
  local default = workspace and join(workspace.root, "install") or vim.fn.getcwd()
  local executables = workspace and M.ros_executables(workspace) or {}
  if #executables > 0 then
    default = executables[1].path
  end

  return vim.fn.input("ROS2 executable: ", default, "file")
end

function M.pick_executable(callback, workspace)
  workspace = workspace or M.require_workspace()
  if not workspace then
    return
  end

  local executables = M.ros_executables(workspace)
  if #executables == 0 then
    notify("No executable ROS2 nodes found under install/*/lib/*/*")
    return
  end

  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then
    vim.ui.select(executables, {
      prompt = "ROS2 executable",
      format_item = function(item)
        return item.label
      end,
    }, callback)
    return
  end

  local finders = require("telescope.finders")
  local conf = require("telescope.config").values
  local actions = require("telescope.actions")
  local action_state = require("telescope.actions.state")

  pickers
    .new({}, {
      prompt_title = "ROS2 executables",
      finder = finders.new_table({
        results = executables,
        entry_maker = function(item)
          return {
            value = item,
            display = string.format("%-40s %s", item.label, item.path),
            ordinal = item.label .. " " .. item.path,
          }
        end,
      }),
      sorter = conf.generic_sorter({}),
      attach_mappings = function(prompt_bufnr)
        actions.select_default:replace(function()
          local entry = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          if entry then
            callback(entry.value)
          end
        end)

        return true
      end,
    })
    :find()
end

function M.select_executable_sync(workspace)
  workspace = workspace or M.require_workspace()
  if not workspace then
    return nil
  end

  local executables = M.ros_executables(workspace)
  if #executables == 0 then
    notify("No executable ROS2 nodes found under install/*/lib/*/*")
    return nil
  end

  if #executables == 1 then
    return executables[1]
  end

  local labels = vim.tbl_map(function(item)
    return item.label
  end, executables)
  local choice = vim.fn.inputlist(vim.list_extend({ "ROS2 executable:" }, labels))
  if choice < 1 or choice > #executables then
    return nil
  end

  return executables[choice]
end

function M.launch_python_node()
  local workspace = M.require_sourced_workspace()
  if not workspace then
    return
  end

  M.pick_executable(function(item)
    if not item then
      return
    end

    local env = M.workspace_env(workspace)
    if not env then
      return
    end

    require("dap").run({
      name = "ROS2 Python: " .. item.label,
      type = "python",
      request = "launch",
      program = item.path,
      cwd = workspace.root,
      env = env,
      args = prompt_args(item.label),
      justMyCode = false,
      console = "integratedTerminal",
    })
  end, workspace)
end

function M.run_command(item, args)
  local workspace = M.require_sourced_workspace()
  if not workspace or not item then
    return nil
  end

  args = args or prompt_args(item.label)

  local command = M.source_command(workspace, true)
  if command ~= "" then
    command = command .. " && "
  end
  command = command .. vim.fn.shellescape(item.path)
  if #args > 0 then
    command = command .. " " .. shell_join(args)
  end

  return command, workspace
end

function M.run_node()
  if not M.run_overseer_template("ROS2: run installed node") then
    notify("overseer.nvim is required for ROS2 run tasks", vim.log.levels.ERROR)
  end
end

function M.launch_current_python_file()
  local program = vim.api.nvim_buf_get_name(0)
  if program == "" then
    notify("Current buffer has no file path")
    return
  end

  local workspace = M.require_sourced_workspace()
  if not workspace then
    return
  end

  local env = M.workspace_env(workspace)
  if not env then
    return
  end

  require("dap").run({
    name = "ROS2 Python: current file",
    type = "python",
    request = "launch",
    program = program,
    cwd = workspace.root,
    env = env,
    args = prompt_args(vim.fn.fnamemodify(program, ":t")),
    justMyCode = false,
    console = "integratedTerminal",
  })
end

function M.launch_cpp_node()
  local workspace = M.require_sourced_workspace()
  if not workspace then
    return
  end

  M.pick_executable(function(item)
    if not item then
      return
    end

    local env = M.workspace_env(workspace)
    if not env then
      return
    end

    require("dap").run({
      name = "ROS2 C++: " .. item.label,
      type = "codelldb",
      request = "launch",
      program = item.path,
      cwd = workspace.root,
      env = env,
      args = prompt_args(item.label),
      stopOnEntry = false,
    })
  end, workspace)
end

function M.attach_process()
  local workspace = M.require_sourced_workspace()
  if not workspace then
    return
  end

  local env = M.workspace_env(workspace)
  if not env then
    return
  end

  require("dap").run({
    name = "ROS2 C++: attach process",
    type = "codelldb",
    request = "attach",
    pid = require("dap.utils").pick_process,
    cwd = workspace.root,
    env = env,
  })
end

function M.inspect_environment()
  local workspace = M.require_workspace()
  if not workspace then
    return
  end

  local executables = M.ros_executables(workspace)
  local env = workspace.setup and M.workspace_env(workspace) or {}
  local keys = {
    "ROS_DISTRO",
    "ROS_VERSION",
    "AMENT_PREFIX_PATH",
    "COLCON_PREFIX_PATH",
    "PYTHONPATH",
    "LD_LIBRARY_PATH",
    "PATH",
  }

  local lines = {
    "ROS2 debug environment",
    "",
    "Workspace: " .. workspace.root,
    "Setup: " .. (workspace.setup or "missing"),
    "Underlay: " .. (ros_underlay_setup() or "not detected"),
    "Executables: " .. tostring(#executables),
    "",
    "Environment:",
  }

  for _, key in ipairs(keys) do
    lines[#lines + 1] = string.format("%s=%s", key, env[key] or "")
  end

  vim.cmd("botright new")
  local bufnr = vim.api.nvim_get_current_buf()
  vim.bo[bufnr].buftype = "nofile"
  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].swapfile = false
  vim.bo[bufnr].filetype = "sh"
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false
end

function M.python_configurations()
  return {
    {
      name = "ROS2 Python: installed node",
      type = "python",
      request = "launch",
      program = M.input_executable_path,
      cwd = M.workspace_root_or_cwd,
      env = M.workspace_env_or_empty,
      args = function()
        return prompt_args("ROS2 Python")
      end,
      justMyCode = false,
      console = "integratedTerminal",
    },
    {
      name = "ROS2 Python: current file",
      type = "python",
      request = "launch",
      program = "${file}",
      cwd = M.workspace_root_or_cwd,
      env = M.workspace_env_or_empty,
      args = function()
        return prompt_args("Current file")
      end,
      justMyCode = false,
      console = "integratedTerminal",
    },
  }
end

function M.cpp_configurations()
  return {
    {
      name = "ROS2 C++: installed node",
      type = "codelldb",
      request = "launch",
      program = M.input_executable_path,
      cwd = M.workspace_root_or_cwd,
      env = M.workspace_env_or_empty,
      args = function()
        return prompt_args("ROS2 C++")
      end,
      stopOnEntry = false,
    },
    {
      name = "ROS2 C++: attach process",
      type = "codelldb",
      request = "attach",
      pid = require("dap.utils").pick_process,
      cwd = M.workspace_root_or_cwd,
      env = M.workspace_env_or_empty,
    },
  }
end

return M
