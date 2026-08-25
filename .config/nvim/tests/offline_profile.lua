local offline = require("config.offline")

assert(offline.load_profile() == nil, offline.profile_error)
assert(offline.enabled(), "profile should enable offline mode")
assert(offline.git_mirror_url() == "https://gitlab.invalid/mirror/github.com/", "profile should load mirror URL")
assert(
  offline.github_url() == "http://nexus.invalid/repository/github.com",
  "GitHub release URL should derive from Nexus"
)
assert(offline.pypi_url() == "http://nexus.invalid/repository/pypi/simple", "PyPI URL should derive from Nexus")
assert(offline.npm_url() == "http://nexus.invalid/repository/npm", "npm URL should derive from Nexus")
assert(
  offline.git_repository_url("tree-sitter/tree-sitter-c")
    == "https://gitlab.invalid/mirror/github.com/tree-sitter/tree-sitter-c.git",
  "repository URL should be direct, mirrored, and suffixed"
)

print("offline profile tests passed")
