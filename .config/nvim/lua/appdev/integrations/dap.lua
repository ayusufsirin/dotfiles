local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.WARN, { title = "appdev.nvim" })
end

function M.load()
  if not package.loaded["dap"] then
    local ok_lazy, lazy = pcall(require, "lazy")
    if ok_lazy then
      pcall(lazy.load, { plugins = { "nvim-dap" } })
    end
  end

  local ok, dap = pcall(require, "dap")
  if not ok then
    notify("nvim-dap is required for appdev debugging", vim.log.levels.ERROR)
    return nil
  end

  return dap
end

function M.run(config)
  local dap = M.load()
  if not dap then
    return nil
  end

  if type(config) == "function" then
    return config(dap)
  end

  if type(config) == "table" then
    dap.run(config)
    return config
  end
end

return M
