local offline = require("config.offline")

assert(offline.enabled(), "offline profile should be enabled")
assert(offline.ready(), "offline profile should have all Nexus endpoints")
assert(#offline.tools == 16, "offline Mason manifest should contain 16 tools")
for _, tool in ipairs(offline.tools) do
  assert(tool.version and tool.force, "offline Mason tools should use trusted pinned versions")
end
assert(#offline.parsers == 22, "offline Tree-sitter manifest should contain 22 parsers")
assert(#offline.parser_repositories == 21, "offline Tree-sitter manifest should contain 21 unique repositories")

local settings = offline.mason_settings()
assert(settings.providers and #settings.providers == 0, "public Mason metadata providers should be disabled")
assert(settings.registries[1] == "lua:config.mason_offline_registry", "local registry should have priority")
assert(
  settings.registries[2] == "github:mason-org/mason-registry@2026-04-06-bumpy-enemy",
  "Mason registry should be pinned"
)
assert(
  settings.github.download_url_template
    == "http://nexus.invalid/repository/github.com/%s/releases/download/%s/%s",
  "GitHub releases should use the Nexus GitHub proxy"
)
assert(settings.pip.install_args[2]:find("nexus.invalid", 1, true), "pip should use Nexus")
assert(settings.pip.install_args[3] == "--trusted-host", "HTTP PyPI should be explicitly trusted")
assert(settings.pip.install_args[4] == "nexus.invalid", "pip should trust only the Nexus authority")
assert(vim.env.PIP_TRUSTED_HOST == "nexus.invalid", "pip subprocesses should trust the HTTP Nexus authority")
assert(settings.npm.install_args[2]:find("nexus.invalid", 1, true), "npm should use Nexus")

local index = require("config.mason_offline_registry")
local cortex = require(index.cortex_debug)
local cortex_url = cortex.source.download.files["marus25.cortex-debug-1.12.1.vsix"]
assert(cortex.source.id == "pkg:generic/cortex-debug@1.12.1", "cortex-debug should not use Open VSX")
assert(
  cortex_url == "http://nexus.invalid/repository/marketplace/cortex-debug-1.12.1.vsix",
  "cortex-debug should use its exact Nexus URL"
)

local install = require("nvim-treesitter.install")
assert(install.prefer_git, "Tree-sitter should prefer Git in offline mode")

print("offline smoke tests passed")
