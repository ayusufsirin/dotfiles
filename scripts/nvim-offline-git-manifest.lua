local repo_root = assert(vim.env.NVIM_DOTFILES_ROOT, "NVIM_DOTFILES_ROOT is required")
package.path = table.concat({
  repo_root .. "/.config/nvim/lua/?.lua",
  repo_root .. "/.config/nvim/lua/?/init.lua",
  package.path,
}, ";")

local repositories = {}

local function add(repository)
  if not repository or repository == "" then
    return
  end
  local url = repository
  if not url:match("^[%a][%w+.-]*://") and not url:match("^git@") then
    url = "https://github.com/" .. url
  end
  if url:find("https://github.com/", 1, true) == 1 and not url:match("%.git$") then
    url = url .. ".git"
  end
  repositories[url] = true
end

local visit

local function visit_list(specs)
  if type(specs) == "string" then
    add(specs)
    return
  end
  if type(specs) ~= "table" then
    return
  end
  for _, spec in ipairs(specs) do
    visit(spec)
  end
end

function visit(spec)
  if type(spec) == "string" then
    add(spec)
    return
  end
  if type(spec) ~= "table" then
    return
  end
  if type(spec[1]) == "string" or type(spec.url) == "string" then
    add(spec.url or spec[1])
    visit_list(spec.dependencies)
    return
  end
  visit_list(spec)
end

add("folke/lazy.nvim")
visit(require("plugins"))
for _, repository in ipairs(require("config.offline").parser_repositories) do
  add(repository)
end

local urls = vim.tbl_keys(repositories)
table.sort(urls)
for _, url in ipairs(urls) do
  io.write(url, "\n")
end
