local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
local offline = require("config.offline")

if not vim.loop.fs_stat(lazypath) then
  local repo = offline.git_repository_url("folke/lazy.nvim")
  local result = vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "--branch=stable",
    repo,
    lazypath,
  })

  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { result, "None" },
    }, true, {})
    vim.cmd.quit()
  end
end

vim.opt.rtp:prepend(lazypath)
