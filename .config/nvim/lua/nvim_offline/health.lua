local M = {}

local offline = require("config.offline")

local function start(name)
  if vim.health.start then
    vim.health.start(name)
  else
    vim.health.report_start(name)
  end
end

local function ok(message)
  if vim.health.ok then
    vim.health.ok(message)
  else
    vim.health.report_ok(message)
  end
end

local function warn(message)
  if vim.health.warn then
    vim.health.warn(message)
  else
    vim.health.report_warn(message)
  end
end

local function error(message)
  if vim.health.error then
    vim.health.error(message)
  else
    vim.health.report_error(message)
  end
end

local function check_executables()
  start("offline prerequisites")
  for _, command in ipairs({ "git", "curl", "tar", "unzip", "python3", "node", "npm" }) do
    if vim.fn.executable(command) == 1 then
      ok(command .. " is available")
    else
      error(command .. " is required")
    end
  end

  if vim.fn.executable("cc") == 1 or vim.fn.executable("gcc") == 1 or vim.fn.executable("clang") == 1 then
    ok("a C compiler is available for Tree-sitter parsers")
  else
    error("a C compiler is required for Tree-sitter parsers")
  end
end

local function check_profile()
  start("offline profile")
  if not offline.enabled() then
    warn("NVIM_OFFLINE is not enabled")
    return
  end

  ok("NVIM_OFFLINE is enabled")
  local missing = offline.missing_settings()
  if #missing == 0 then
    ok("GitHub release artifact, Cortex Debug, PyPI, and npm endpoints are configured")
    ok("Mason registry is pinned to " .. offline.registry_version)
  else
    error("missing settings: " .. table.concat(missing, ", "))
  end

  local uname = vim.uv.os_uname()
  if uname.sysname == "Linux" and uname.machine == "x86_64" then
    ok("supported platform: Linux x86-64")
  else
    error("unsupported platform: " .. uname.sysname .. " " .. uname.machine)
  end

  local parser_url = offline.git_repository_url("tree-sitter/tree-sitter-c")
  if parser_url == "https://github.com/tree-sitter/tree-sitter-c.git" then
    ok("Git clones use canonical URLs with the required .git suffix")
  else
    error("Git clone URLs are not canonical or are missing the .git suffix")
  end
end

local function check_mason()
  start("pinned Mason tools")
  local package_root = vim.fn.stdpath("data") .. "/mason/packages"
  for _, tool in ipairs(offline.tools) do
    local receipt = package_root .. "/" .. tool[1] .. "/mason-receipt.json"
    if vim.fn.filereadable(receipt) == 1 then
      local success, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(receipt), "\n"))
      local source_id = success and decoded.source and decoded.source.id or ""
      if source_id:sub(-#tool.version) == tool.version then
        ok(tool[1] .. " " .. tool.version)
      else
        warn(tool[1] .. " is installed, but not at pinned version " .. tool.version)
      end
    else
      error(tool[1] .. " " .. tool.version .. " is not installed")
    end
  end
end

local function check_parsers()
  start("Tree-sitter parsers")
  local missing = {}
  for _, parser in ipairs(offline.parsers) do
    if #vim.api.nvim_get_runtime_file("parser/" .. parser .. ".so", false) == 0 then
      table.insert(missing, parser)
    end
  end

  if #missing == 0 then
    ok("all " .. #offline.parsers .. " configured parsers are installed")
  else
    error("missing parsers: " .. table.concat(missing, ", "))
  end
end

function M.check()
  check_profile()
  check_executables()
  check_mason()
  check_parsers()
end

return M
