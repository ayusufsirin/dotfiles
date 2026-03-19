local M = {}

local levels = { "error", "warn", "info", "hint" }

local labels = {
  error = "Errors",
  warn = "Warnings",
  info = "Info",
  hint = "Hints",
}

local icons = {
  error = "",
  warn = "",
  info = "",
  hint = "󰌵",
}

local mode_names = {
  error = "buffer_errors",
  warn = "buffer_warnings",
  info = "buffer_info",
  hint = "buffer_hints",
}

local severity_map = {
  error = vim.diagnostic.severity.ERROR,
  warn = vim.diagnostic.severity.WARN,
  info = vim.diagnostic.severity.INFO,
  hint = vim.diagnostic.severity.HINT,
}

local source_bufnr = nil

local function refresh_statusline()
  if package.loaded["lualine"] then
    vim.schedule(function()
      require("lualine").refresh()
    end)
  else
    vim.cmd.redrawstatus()
  end
end

local function valid_buf(bufnr)
  return bufnr and vim.api.nvim_buf_is_valid(bufnr)
end

local function current_source_bufnr()
  if vim.bo.filetype ~= "trouble" then
    source_bufnr = vim.api.nvim_get_current_buf()
  end

  if valid_buf(source_bufnr) then
    return source_bufnr
  end

  return nil
end

function M.set_source_bufnr(bufnr)
  if valid_buf(bufnr) and vim.bo[bufnr].filetype ~= "trouble" then
    source_bufnr = bufnr
  end
end

function M.count(level, bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  return #vim.diagnostic.get(bufnr, { severity = severity_map[level] })
end

function M.mode_name(level)
  return mode_names[level]
end

function M.icon(level)
  return icons[level]
end

function M.label(level)
  return labels[level]
end

function M.is_open(level)
  local ok, trouble = pcall(require, "trouble")
  if not ok then
    return false
  end

  return trouble.is_open(mode_names[level])
end

function M.any_open()
  for _, level in ipairs(levels) do
    if M.is_open(level) then
      return true
    end
  end

  return false
end

function M.close_all()
  local ok, trouble = pcall(require, "trouble")
  if not ok then
    return
  end

  for _, level in ipairs(levels) do
    if trouble.is_open(mode_names[level]) then
      trouble.close(mode_names[level])
    end
  end

  refresh_statusline()
end

function M.open(level)
  local ok, trouble = pcall(require, "trouble")
  if not ok then
    return
  end

  local bufnr = current_source_bufnr()
  return M.open_for_buf(level, bufnr, { notify_empty = false, close_on_empty = false })
end

function M.open_for_buf(level, bufnr, opts)
  local ok, trouble = pcall(require, "trouble")
  if not ok then
    return
  end

  opts = opts or {}

  if not valid_buf(bufnr) then
    vim.notify("No source buffer for diagnostics", vim.log.levels.WARN)
    return
  end

  M.set_source_bufnr(bufnr)

  local mode = mode_names[level]
  if M.count(level, bufnr) == 0 then
    if opts.notify_empty ~= false then
      vim.notify("No " .. labels[level]:lower() .. " in current buffer", vim.log.levels.INFO)
    end
    if opts.close_on_empty then
      M.close_all()
    else
      vim.schedule(function()
        require("config.diagnostics").set_trouble_winbar()
        refresh_statusline()
      end)
    end
    return
  end

  M.close_all()
  local view = trouble.open({
    mode = mode,
    filter = {
      buf = bufnr,
      severity = severity_map[level],
    },
  })
  if view and view.wait then
    view:wait(function()
      if view.win and view.win.win and vim.api.nvim_win_is_valid(view.win.win) then
        require("config.diagnostics").set_trouble_winbar(view.win.win)
      end
      refresh_statusline()
    end)
  else
    vim.schedule(function()
      require("config.diagnostics").set_trouble_winbar()
      refresh_statusline()
    end)
  end
end

function M.sync_to_buffer(bufnr)
  if not valid_buf(bufnr) or vim.bo[bufnr].filetype == "trouble" or not M.any_open() then
    return
  end

  M.set_source_bufnr(bufnr)
  local active = M.active_level(M.active_winid())
  if not active then
    return
  end

  M.open_for_buf(active, bufnr, { notify_empty = false, close_on_empty = true })
end

function M.toggle(level)
  local ok, trouble = pcall(require, "trouble")
  if not ok then
    return
  end

  local mode = mode_names[level]
  if trouble.is_open(mode) then
    trouble.close(mode)
    refresh_statusline()
    return
  end

  M.open(level)
end

function M.active_level(winid)
  local ok, trouble = pcall(require, "trouble")
  if not ok or not trouble._find_last then
    return nil
  end

  winid = winid or vim.api.nvim_get_current_win()

  for _, level in ipairs(levels) do
    local view = trouble._find_last(mode_names[level])
    if view and view.win and view.win.win == winid then
      return level
    end
  end

  return nil
end

function M.active_winid()
  local ok, trouble = pcall(require, "trouble")
  if not ok or not trouble._find_last then
    return nil
  end

  for _, level in ipairs(levels) do
    local view = trouble._find_last(mode_names[level])
    if view and view.win and view.win.win and vim.api.nvim_win_is_valid(view.win.win) then
      return view.win.win
    end
  end

  return nil
end

local function button(level, active)
  local hl = active == level and "%#TabLineSel#" or "%#TabLine#"
  return table.concat({
    hl,
    "%@v:lua.DiagnosticsOpen" .. labels[level] .. "@",
    " " .. icons[level] .. " " .. labels[level] .. " ",
    "%T",
  })
end

function M.set_trouble_winbar(winid)
  winid = winid or M.active_winid()
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    return
  end

  local active = M.active_level(winid)
  if not active then
    return
  end

  local winbar = table.concat({
    button("error", active),
    button("warn", active),
    button("info", active),
    button("hint", active),
    "%=",
    "%#TabLine#",
    "%@v:lua.DiagnosticsCloseAll@",
    " 󰅖 ",
    "%T",
    "%*",
  })

  vim.api.nvim_set_option_value("winbar", winbar, { scope = "local", win = winid })
end

function M.setup_click_handlers()
  _G.DiagnosticsOpenErrors = function()
    require("config.diagnostics").open("error")
  end

  _G.DiagnosticsOpenWarnings = function()
    require("config.diagnostics").open("warn")
  end

  _G.DiagnosticsOpenInfo = function()
    require("config.diagnostics").open("info")
  end

  _G.DiagnosticsOpenHints = function()
    require("config.diagnostics").open("hint")
  end

  _G.DiagnosticsCloseAll = function()
    require("config.diagnostics").close_all()
  end
end

return M
