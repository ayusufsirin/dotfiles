local opt = vim.opt

vim.g.loaded_perl_provider = 0
vim.g.loaded_ruby_provider = 0

local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
local path_sep = vim.fn.has("win32") == 1 and ";" or ":"
if not vim.env.PATH:find(mason_bin, 1, true) then
  vim.env.PATH = mason_bin .. path_sep .. vim.env.PATH
end

opt.termguicolors = true
opt.mouse = "a"
opt.mousemodel = "extend"
opt.mousescroll = "ver:3,hor:6"
opt.smoothscroll = true
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.wrap = false
opt.statuscolumn = table.concat({
  "%@v:lua.ScDapBreakpoint@",
  "%s",
  "%T",
  "%=",
  "%{v:relnum == 0 ? v:lnum : v:relnum} ",
})
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.showmode = false
opt.breakindent = true
opt.linebreak = true
opt.splitbelow = true
opt.splitright = true
opt.ignorecase = true
opt.smartcase = true
opt.hlsearch = true
opt.incsearch = true
opt.completeopt = { "menu", "menuone", "noselect" }
opt.pumheight = 12
opt.updatetime = 200
opt.timeoutlen = 400
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.undofile = true
opt.clipboard = "unnamedplus"
opt.expandtab = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.shiftround = true
opt.smartindent = true
opt.confirm = true
opt.sessionoptions = {
  "curdir",
  "folds",
  "help",
  "tabpages",
  "winsize",
  "terminal",
}

local state = vim.fn.stdpath("state")
local undo = state .. "/undo"
local swap = state .. "/swap"
local backup = state .. "/backup"
local view = state .. "/view"

opt.undodir = undo
opt.directory = swap
opt.backupdir = backup
opt.viewdir = view

vim.fn.mkdir(undo, "p")
vim.fn.mkdir(swap, "p")
vim.fn.mkdir(backup, "p")
vim.fn.mkdir(view, "p")
