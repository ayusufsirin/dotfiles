-- Requires installed plugins/parsers. Run: nvim --headless --clean -u NONE -l .config/nvim/tests/treesitter_injections.lua
local config = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(config)
local plugins = vim.fn.stdpath("data") .. "/lazy/"
vim.opt.runtimepath:prepend(plugins .. "nvim-treesitter")
vim.opt.runtimepath:prepend(plugins .. "nvim-treesitter-textobjects")
vim.cmd("runtime plugin/nvim-treesitter.lua")
package.loaded["config.offline"] = { enabled = function() return false end, parsers = {} }
require("plugins.treesitter")[1].config()

local function parse(language, lines)
  local bufnr = vim.api.nvim_create_buf(true, false)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].filetype = language
  local parser = vim.treesitter.get_parser(bufnr)
  assert(parser:parse(true), "synchronous parsing did not finish")

  parser:invalidate(true)
  local finished, parse_error = false, nil
  parser:parse(true, function(err)
    parse_error = err
    finished = true
  end)
  assert(vim.wait(1000, function() return finished end), "asynchronous parsing did not finish")
  assert(not parse_error, parse_error)
  return parser
end

local heredoc = { "cat << LUA", "print('hello')", "LUA" }
local bash = parse("bash", heredoc)
assert(bash:children().lua, "uppercase heredoc delimiter did not inject Lua")

local markdown = parse("markdown", { "# Example", "", "```bash", "cat << LUA", "print('hello')", "LUA", "```" })
assert(markdown:children().bash, "Markdown code fence did not inject Bash")
assert(markdown:children().bash:children().lua, "nested heredoc did not inject Lua")

parse("bash", { "echo hello" })
local messages = vim.api.nvim_exec2("messages", { output = true }).output
assert(not messages:match("E%d+:"), messages)
print("Tree-sitter injection tests passed")
