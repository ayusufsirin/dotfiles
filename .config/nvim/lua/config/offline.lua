local M = {}

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

function M.enabled()
  return truthy((vim.env.NVIM_OFFLINE or ""):lower())
end

function M.raw_url()
  return trim_trailing_slash(vim.env.NVIM_NEXUS_RAW_URL)
end

function M.github_url()
  return trim_trailing_slash(vim.env.NVIM_NEXUS_GITHUB_URL)
end

function M.pypi_url()
  return trim_trailing_slash(vim.env.NVIM_NEXUS_PYPI_URL or vim.env.PIP_INDEX_URL)
end

function M.pypi_trusted_host()
  local url = M.pypi_url()
  return url and url:match("^http://([^/:]+)") or nil
end

function M.npm_url()
  return trim_trailing_slash(vim.env.NVIM_NEXUS_NPM_URL or vim.env.NPM_CONFIG_REGISTRY)
end

function M.missing_settings()
  if not M.enabled() then
    return {}
  end

  local missing = {}
  if not M.github_url() and not M.raw_url() then
    table.insert(missing, "NVIM_NEXUS_GITHUB_URL or NVIM_NEXUS_RAW_URL")
  end
  if not trim_trailing_slash(vim.env.NVIM_NEXUS_CORTEX_DEBUG_URL) and not M.raw_url() then
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
    return M.raw_url()
      .. "/openvsx/marus25/cortex-debug/1.12.1/marus25.cortex-debug-1.12.1.vsix"
  end
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
