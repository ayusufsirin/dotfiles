local offline = require("config.offline")

local failures = {}

local function check(condition, message)
  if condition then
    print("OK: " .. message)
  else
    table.insert(failures, message)
    print("ERROR: " .. message)
  end
end

check(offline.enabled(), "offline profile is enabled")
check(offline.ready(), "all offline endpoints are configured")

for _, command in ipairs({ "git", "curl", "tar", "unzip", "python3", "node", "npm" }) do
  check(vim.fn.executable(command) == 1, command .. " is available")
end
check(
  vim.fn.executable("cc") == 1 or vim.fn.executable("gcc") == 1 or vim.fn.executable("clang") == 1,
  "a C compiler is available"
)

local package_root = vim.fn.stdpath("data") .. "/mason/packages"
for _, tool in ipairs(offline.tools) do
  local receipt = package_root .. "/" .. tool[1] .. "/mason-receipt.json"
  local receipt_ok = vim.fn.filereadable(receipt) == 1
  local version_ok = false
  if receipt_ok then
    local decode_ok, decoded = pcall(vim.json.decode, table.concat(vim.fn.readfile(receipt), "\n"))
    local source_id = decode_ok and decoded.source and decoded.source.id or ""
    version_ok = source_id:sub(-#tool.version) == tool.version
  end
  check(receipt_ok and version_ok, tool[1] .. " has pinned receipt " .. tool.version)
end

for _, parser in ipairs(offline.parsers) do
  check(#vim.api.nvim_get_runtime_file("parser/" .. parser .. ".so", false) > 0, parser .. " parser artifact exists")
end

if #failures > 0 then
  print(string.format("offline installation verification failed with %d error(s)", #failures))
  vim.cmd("cquit 1")
  return
end

print(
  string.format(
    "offline installation verified: %d Mason tools and %d Tree-sitter parsers",
    #offline.tools,
    #offline.parsers
  )
)
