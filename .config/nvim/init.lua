vim.g.mapleader = " "
vim.g.maplocalleader = ","

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")

require("lazy").setup(require("plugins"), {
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    enabled = false,
  },
  ui = {
    border = "rounded",
  },
})
