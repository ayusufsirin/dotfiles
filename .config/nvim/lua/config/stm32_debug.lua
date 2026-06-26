local utils = require("config.dev_utils")

local M = {}

local join = utils.join
local normalize = utils.normalize
local is_file = utils.is_file
local is_dir = utils.is_dir

local BUILD_CONFIG_ORDER = { "Debug", "Release" }

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

return M
