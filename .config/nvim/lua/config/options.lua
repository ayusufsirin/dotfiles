local opt = vim.opt

opt.termguicolors = true
opt.number = true
opt.relativenumber = true
opt.signcolumn = "yes"
opt.cursorline = true
opt.wrap = false
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
