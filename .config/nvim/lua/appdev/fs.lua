local M = {}

function M.join(...)
  local parts = vim.tbl_filter(function(part)
    return part ~= nil and part ~= ""
  end, { ... })

  if vim.fs and vim.fs.joinpath then
    return vim.fs.joinpath(unpack(parts))
  end

  return table.concat(parts, "/"):gsub("//+", "/")
end

function M.dirname(path)
  if vim.fs and vim.fs.dirname then
    return vim.fs.dirname(path)
  end

  return vim.fn.fnamemodify(path, ":h")
end

function M.normalize(path)
  if not path or path == "" then
    return path
  end

  if vim.fs and vim.fs.normalize then
    return vim.fs.normalize(path)
  end

  return vim.fn.fnamemodify(path, ":p")
end

function M.is_file(path)
  return path and vim.fn.filereadable(path) == 1
end

function M.is_dir(path)
  return path and vim.fn.isdirectory(path) == 1
end

function M.start_path(path)
  path = path or vim.api.nvim_buf_get_name(0)
  if path == "" then
    path = vim.fn.getcwd()
  end

  path = M.normalize(path)
  if M.is_file(path) then
    path = M.dirname(path)
  end

  return path
end

function M.find_upward(path, matcher)
  local dir = M.start_path(path)

  while dir and dir ~= "" do
    local result = matcher(dir)
    if result then
      return result
    end

    local parent = M.dirname(dir)
    if parent == dir then
      break
    end
    dir = parent
  end
end

function M.shell_join(args)
  return table.concat(vim.tbl_map(vim.fn.shellescape, args or {}), " ")
end

function M.executable(command)
  return command ~= nil and command ~= "" and vim.fn.executable(command) == 1
end

function M.command_availability(commands)
  local available = {}
  local missing = {}

  for _, command in ipairs(commands or {}) do
    if M.executable(command) then
      available[#available + 1] = command
    else
      missing[#missing + 1] = command
    end
  end

  return {
    ok = #missing == 0,
    available = available,
    missing = missing,
  }
end

return M
