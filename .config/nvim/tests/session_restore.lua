-- Run from the repository root: nvim --headless --clean -u NONE -l .config/nvim/tests/session_restore.lua
local config = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
vim.opt.runtimepath:prepend(config)

local function noop() end
for _, name in ipairs({ "terminal", "splitview", "diagnostics", "debug_ui", "gitinspect" }) do
  package.loaded["config." .. name] = {
    setup_click_handlers = noop,
    sync_to_buffer = noop,
    set_file_winbar = noop,
    set_popup_winbar = noop,
  }
end

vim.cmd("filetype plugin on")
local markdown = vim.api.nvim_get_current_buf()
local markdown_win = vim.api.nvim_get_current_win()
vim.api.nvim_buf_set_name(markdown, vim.fn.tempname() .. ".md")
vim.bo[markdown].filetype = "markdown"

local undetected = vim.api.nvim_create_buf(true, false)
vim.api.nvim_buf_set_name(undetected, vim.fn.tempname() .. ".lua")
assert(vim.bo[undetected].filetype == "")

vim.cmd("vnew")
local tree = vim.api.nvim_get_current_buf()
local tree_win = vim.api.nvim_get_current_win()
vim.api.nvim_buf_set_name(tree, "NvimTree_1")
vim.bo[tree].buftype = "nofile"
vim.bo[tree].filetype = "NvimTree"
vim.wo.spell = false
vim.bo[tree].textwidth = 0
vim.wo.wrap = false

require("config.autocmds")

local events = { [markdown] = {}, [undetected] = {} }
local mismatches = {}
vim.api.nvim_create_autocmd({ "BufReadPost", "FileType" }, {
  callback = function(args)
    if events[args.buf] then
      events[args.buf][args.event] = true
      if vim.api.nvim_get_current_buf() ~= args.buf then
        mismatches[#mismatches + 1] = args.event .. " ran in the wrong buffer"
      end
    end
  end,
})

vim.api.nvim_exec_autocmds("User", { pattern = "PersistenceLoadPost", modeline = false })
local finished = false
vim.schedule(function()
  finished = true
end)
assert(vim.wait(1000, function()
  return finished
end), "scheduled session refresh did not finish")

assert(#mismatches == 0, table.concat(mismatches, "\n"))
local messages = vim.api.nvim_exec2("messages", { output = true }).output
assert(not messages:match("E%d+:"), messages)
for bufnr, seen in pairs(events) do
  assert(seen.BufReadPost and seen.FileType, "restored buffer missed refresh events")
  assert(vim.treesitter.highlighter.active[bufnr], "restored buffer missed Tree-sitter highlighting")
end
assert(vim.bo[undetected].filetype == "lua", "restored filetype was not detected")
assert(vim.wo[markdown_win].spell and vim.bo[markdown].textwidth == 88, "Markdown settings were not restored")
assert(vim.api.nvim_get_current_win() == tree_win, "refresh changed the focused window")
assert(vim.api.nvim_get_current_buf() == tree, "refresh changed the focused buffer")
assert(vim.bo[tree].filetype == "NvimTree" and vim.bo[tree].buftype == "nofile")
assert(not vim.wo.spell and vim.bo[tree].textwidth == 0 and not vim.wo.wrap, "refresh changed tree settings")
assert(vim.fn.maparg("gO", "n", false, true).buffer ~= 1, "Markdown mappings leaked into the tree")
print("session restore tests passed")
