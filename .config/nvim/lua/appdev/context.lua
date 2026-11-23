local fs = require("appdev.fs")

local M = {}

local cache = {}

function M.from_path(path)
  local bufnr = vim.api.nvim_get_current_buf()
  local buffer_path = path or vim.api.nvim_buf_get_name(bufnr)
  local start = fs.start_path(buffer_path)

  return {
    bufnr = bufnr,
    cwd = fs.normalize(vim.fn.getcwd()),
    path = buffer_path ~= "" and fs.normalize(buffer_path) or start,
    start = start,
    filetype = vim.bo[bufnr].filetype,
  }
end

function M.clear()
  cache = {}
end

function M.active(path)
  local ctx = M.from_path(path)
  local key = table.concat({ ctx.cwd or "", ctx.start or "", ctx.filetype or "" }, "\n")
  if cache[key] ~= nil then
    return cache[key]
  end

  local active = require("appdev.registry").detect(ctx) or false
  cache[key] = active
  return active or nil
end

return M
