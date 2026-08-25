local M = {}

local profile_keys = {
  NVIM_OFFLINE = true,
  NVIM_NEXUS_URL = true,
  NVIM_GITHUB_GIT_MIRROR_BASE = true,
  NVIM_GITLAB_CA_FILE = true,
  NVIM_GITHUB_RELEASE_BASE_URL = true,
  NVIM_NEXUS_GITHUB_URL = true,
  NVIM_NEXUS_CORTEX_DEBUG_URL = true,
  NVIM_NEXUS_PYPI_URL = true,
  NVIM_NEXUS_NPM_URL = true,
  NVIM_NEXUS_RAW_URL = true,
  PIP_INDEX_URL = true,
  NPM_CONFIG_REGISTRY = true,
}

M.registry_version = "2026-04-06-bumpy-enemy"

local function pinned(name, version)
  return { name, version = version, force = true }
end

M.tools = {
  pinned("clangd", "22.1.0"),
  pinned("clang-format", "22.1.2"),
  pinned("codelldb", "v1.12.1"),
  pinned("cortex-debug", "1.12.1"),
  pinned("debugpy", "1.8.20"),
  pinned("lua-language-server", "3.18.0"),
  pinned("markdownlint-cli2", "0.22.0"),
  pinned("marksman", "2026-02-08"),
  pinned("prettier", "3.8.1"),
  pinned("pyright", "1.1.408"),
  pinned("rstcheck", "6.2.5"),
  pinned("ruff", "0.15.16"),
  pinned("shellcheck", "v0.11.0"),
  pinned("shfmt", "v3.13.0"),
  pinned("stylua", "v2.4.0"),
  pinned("yaml-language-server", "1.21.0"),
}

M.parsers = {
  "bash",
  "c",
  "cpp",
  "comment",
  "css",
  "dockerfile",
  "git_config",
  "gitcommit",
  "gitignore",
  "go",
  "json",
  "lua",
  "markdown",
  "markdown_inline",
  "python",
  "query",
  "rst",
  "rust",
  "toml",
  "vim",
  "vimdoc",
  "yaml",
}

M.parser_repositories = {
  "tree-sitter/tree-sitter-bash",
  "tree-sitter/tree-sitter-c",
  "tree-sitter/tree-sitter-cpp",
  "stsewd/tree-sitter-comment",
  "tree-sitter/tree-sitter-css",
  "camdencheek/tree-sitter-dockerfile",
  "the-mikedavis/tree-sitter-git-config",
  "gbprod/tree-sitter-gitcommit",
  "shunsambongi/tree-sitter-gitignore",
  "tree-sitter/tree-sitter-go",
  "tree-sitter/tree-sitter-json",
  "MunifTanjim/tree-sitter-lua",
  "MDeiml/tree-sitter-markdown",
  "tree-sitter/tree-sitter-python",
  "nvim-treesitter/tree-sitter-query",
  "stsewd/tree-sitter-rst",
  "tree-sitter/tree-sitter-rust",
  "tree-sitter-grammars/tree-sitter-toml",
  "neovim/tree-sitter-vim",
  "neovim/tree-sitter-vimdoc",
  "tree-sitter-grammars/tree-sitter-yaml",
}

local function truthy(value)
  return value == "1" or value == "true" or value == "yes" or value == "on"
end

local function trim_trailing_slash(value)
  if not value or value == "" then
    return nil
  end
  return (value:gsub("/+$", ""))
end

local function nexus_repository(path)
  local nexus_url = trim_trailing_slash(vim.env.NVIM_NEXUS_URL)
  return nexus_url and (nexus_url .. path) or nil
end

local function unquote(value)
  if #value >= 2 then
    local first = value:sub(1, 1)
    local last = value:sub(-1)
    if (first == '"' and last == '"') or (first == "'" and last == "'") then
      return value:sub(2, -2)
    end
  end
  return value
end

function M.profile_file()
  return vim.env.NVIM_OFFLINE_PROFILE or vim.fn.expand("~/.config/nvim-offline/env")
end

function M.load_profile()
  if M._profile_loaded then
    return M.profile_error
  end
  M._profile_loaded = true

  local profile_file = M.profile_file()
  if vim.fn.filereadable(profile_file) ~= 1 then
    if vim.env.NVIM_OFFLINE_PROFILE then
      M.profile_error = "offline profile is missing or unreadable: " .. profile_file
    end
    return M.profile_error
  end

  for line_number, original_line in ipairs(vim.fn.readfile(profile_file)) do
    local line = vim.trim(original_line)
    if line ~= "" and not line:match("^#") then
      local key, value = line:match("^([A-Z][A-Z0-9_]*)=(.*)$")
      if not key then
        M.profile_error = string.format("invalid offline profile line %d", line_number)
        return M.profile_error
      end
      if not profile_keys[key] then
        M.profile_error = string.format("unknown offline profile setting on line %d: %s", line_number, key)
        return M.profile_error
      end
      if vim.env[key] == nil then
        vim.env[key] = unquote(vim.trim(value))
      end
    end
  end
  return nil
end

function M.enabled()
  return truthy((vim.env.NVIM_OFFLINE or ""):lower())
end

function M.raw_url()
  return trim_trailing_slash(vim.env.NVIM_NEXUS_RAW_URL)
end

function M.github_url()
  return trim_trailing_slash(vim.env.NVIM_GITHUB_RELEASE_BASE_URL)
    or trim_trailing_slash(vim.env.NVIM_NEXUS_GITHUB_URL)
    or nexus_repository("/repository/github.com")
end

function M.git_mirror_url()
  local mirror_url = trim_trailing_slash(vim.env.NVIM_GITHUB_GIT_MIRROR_BASE)
  return mirror_url and (mirror_url .. "/") or nil
end

function M.git_repository_url(repository)
  local path = repository:gsub("^https://github%.com/", "")
  if not path:match("%.git$") then
    path = path .. ".git"
  end
  local mirror_url = M.enabled() and M.git_mirror_url() or nil
  return (mirror_url or "https://github.com/") .. path
end

function M.git_url_format()
  local mirror_url = M.enabled() and M.git_mirror_url() or nil
  return mirror_url and (mirror_url .. "%s.git") or nil
end

function M.pypi_url()
  return trim_trailing_slash(vim.env.NVIM_NEXUS_PYPI_URL or vim.env.PIP_INDEX_URL)
    or nexus_repository("/repository/pypi/simple")
end

function M.pypi_trusted_host()
  local url = M.pypi_url()
  return url and url:match("^http://([^/:]+)") or nil
end

function M.npm_url()
  return trim_trailing_slash(vim.env.NVIM_NEXUS_NPM_URL or vim.env.NPM_CONFIG_REGISTRY)
    or nexus_repository("/repository/npm")
end

function M.resolved_git_url(source_url)
  local resolved = vim.fn.systemlist({ "git", "ls-remote", "--get-url", source_url })
  if vim.v.shell_error ~= 0 then
    return nil
  end
  return resolved[1]
end

function M.git_routing_ready()
  if M.git_mirror_url() then
    local expected = M.git_mirror_url() .. "tree-sitter/tree-sitter-c.git"
    return M.git_repository_url("tree-sitter/tree-sitter-c") == expected
  end
  local source_url = "https://github.com/tree-sitter/tree-sitter-c.git"
  local resolved = M.resolved_git_url(source_url)
  if not resolved or resolved == source_url or not resolved:match("%.git$") then
    return false
  end
  return true
end

function M.missing_settings()
  if not M.enabled() then
    return {}
  end

  local missing = {}
  if M.profile_error then
    table.insert(missing, M.profile_error)
  end
  if not M.git_routing_ready() then
    table.insert(missing, "NVIM_GITHUB_GIT_MIRROR_BASE or a working GitHub insteadOf rule")
  end
  if not M.github_url() and not M.raw_url() then
    table.insert(missing, "NVIM_NEXUS_URL, NVIM_GITHUB_RELEASE_BASE_URL, or NVIM_NEXUS_RAW_URL")
  end
  if not M.cortex_debug_url() then
    table.insert(missing, "NVIM_NEXUS_CORTEX_DEBUG_URL or NVIM_NEXUS_RAW_URL")
  end
  if not M.pypi_url() then
    table.insert(missing, "NVIM_NEXUS_PYPI_URL or PIP_INDEX_URL")
  end
  if not M.npm_url() then
    table.insert(missing, "NVIM_NEXUS_NPM_URL or NPM_CONFIG_REGISTRY")
  end
  return missing
end

function M.ready()
  return M.enabled() and #M.missing_settings() == 0
end

function M.apply_client_environment()
  if not M.enabled() then
    return
  end

  if M.pypi_url() then
    vim.env.PIP_INDEX_URL = M.pypi_url()
  end
  local trusted_host = M.pypi_trusted_host()
  if trusted_host and not (vim.env.PIP_TRUSTED_HOST or ""):find(trusted_host, 1, true) then
    vim.env.PIP_TRUSTED_HOST = vim.env.PIP_TRUSTED_HOST and (vim.env.PIP_TRUSTED_HOST .. " " .. trusted_host)
      or trusted_host
  end
  if M.npm_url() then
    vim.env.NPM_CONFIG_REGISTRY = M.npm_url()
  end
end

local function append_git_config(key, value)
  local count = tonumber(vim.env.GIT_CONFIG_COUNT or "0")
  if not count then
    M.profile_error = "GIT_CONFIG_COUNT must be numeric"
    return
  end
  for index = 0, count - 1 do
    if vim.env["GIT_CONFIG_KEY_" .. index] == key then
      return
    end
  end
  vim.env["GIT_CONFIG_KEY_" .. count] = key
  vim.env["GIT_CONFIG_VALUE_" .. count] = value
  vim.env.GIT_CONFIG_COUNT = tostring(count + 1)
end

function M.apply_git_environment()
  if not M.enabled() then
    return
  end
  local mirror_url = M.git_mirror_url()
  if mirror_url then
    append_git_config("url." .. mirror_url .. ".insteadOf", "https://github.com/")
  end
  local ca_file = vim.env.NVIM_GITLAB_CA_FILE
  if ca_file and ca_file ~= "" and not vim.env.GIT_SSL_CAINFO then
    if vim.fn.filereadable(ca_file) == 1 then
      vim.env.GIT_SSL_CAINFO = ca_file
    else
      M.profile_error = "internal Git CA file is unreadable: " .. ca_file
    end
  end
end

function M.github_download_template()
  if M.github_url() then
    return M.github_url() .. "/%s/releases/download/%s/%s"
  end
  if M.raw_url() then
    return M.raw_url() .. "/github/%s/releases/download/%s/%s"
  end
end

function M.cortex_debug_url()
  local exact_url = trim_trailing_slash(vim.env.NVIM_NEXUS_CORTEX_DEBUG_URL)
  if exact_url then
    return exact_url
  end
  if M.raw_url() then
    return M.raw_url() .. "/openvsx/marus25/cortex-debug/1.12.1/marus25.cortex-debug-1.12.1.vsix"
  end
  return nexus_repository(
    "/repository/marketplace.visualstudio.com/_apis/public/gallery/publishers/marus25/vsextensions/cortex-debug/1.12.1/vspackage"
  )
end

function M.normalize_treesitter_git_urls()
  local parser_configs = require("nvim-treesitter.parsers").get_parser_configs()
  local repositories = {}
  for _, parser in ipairs(M.parsers) do
    local parser_config = parser_configs[parser]
    local install_info = parser_config and parser_config.install_info
    local url = install_info and install_info.url
    if url then
      if url:find("https://github.com/", 1, true) == 1 then
        url = M.git_repository_url(url)
        install_info.url = url
      elseif M.git_mirror_url() and url:find(M.git_mirror_url(), 1, true) == 1 and not url:match("%.git$") then
        url = url .. ".git"
        install_info.url = url
      end
      if url:match("%.git$") then
        repositories[url] = true
      end
    end
  end
  return vim.tbl_keys(repositories)
end

function M.mason_settings()
  local settings = {
    ui = {
      border = "rounded",
    },
  }

  if not M.enabled() then
    return settings
  end

  if not M.ready() then
    settings.registries = { "lua:config.mason_empty_registry" }
    settings.providers = {}
    settings.registry_cache = { refresh = true, duration = 365 * 24 * 60 * 60 }
    return settings
  end

  settings.registries = {
    "lua:config.mason_offline_registry",
    "github:mason-org/mason-registry@" .. M.registry_version,
  }
  settings.providers = {}
  settings.registry_cache = { refresh = true, duration = 365 * 24 * 60 * 60 }
  settings.github = {
    download_url_template = M.github_download_template(),
  }
  local pip_args = { "--index-url", M.pypi_url() }
  local trusted_host = M.pypi_trusted_host()
  if trusted_host then
    table.insert(pip_args, "--trusted-host")
    table.insert(pip_args, trusted_host)
  end
  settings.pip = { upgrade_pip = false, install_args = pip_args }
  settings.npm = {
    install_args = { "--registry", M.npm_url() },
  }
  return settings
end

function M.ensure_installed(default_tools)
  if M.enabled() then
    return vim.deepcopy(M.tools)
  end
  return default_tools
end

function M.setup()
  M.load_profile()
  M.apply_git_environment()
  M.apply_client_environment()

  vim.api.nvim_create_user_command("NvimOfflineHealth", function()
    vim.cmd("checkhealth nvim_offline")
  end, { desc = "Check the offline Neovim installation" })

  if M.enabled() and not M.ready() then
    local missing = table.concat(M.missing_settings(), ", ")
    vim.schedule(function()
      vim.notify(
        "Offline Neovim profile is incomplete; Mason downloads are disabled. Missing: " .. missing,
        vim.log.levels.ERROR
      )
    end)
  end
end

return M
