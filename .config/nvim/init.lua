vim.g.mapleader = " "
vim.g.maplocalleader = ","

require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.offline").setup()
require("config.lazy")

local lazy_options = {
  checker = {
    enabled = true,
    notify = false,
  },
  change_detection = {
    enabled = false,
  },
  rocks = {
    enabled = false,
  },
  ui = {
    border = "rounded",
  },
}
local git_url_format = require("config.offline").git_url_format()
if git_url_format then
  lazy_options.git = { url_format = git_url_format }
end

require("lazy").setup(require("plugins"), lazy_options)
