local M = {}

local handlers_registered = false
local listeners_registered = false

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.WARN, { title = "Debug UI" })
end

local function normal_buffer(bufnr)
  return bufnr
    and vim.api.nvim_buf_is_valid(bufnr)
    and vim.bo[bufnr].buftype == ""
    and vim.bo[bufnr].filetype ~= "NvimTree"
end

local function source_context(args)
  local mousepos = type(args) == "table" and args.mousepos or nil
  local winid
  local bufnr
  local lnum

  if mousepos and mousepos.winid and mousepos.winid ~= 0 and vim.api.nvim_win_is_valid(mousepos.winid) then
    winid = mousepos.winid
    bufnr = vim.api.nvim_win_get_buf(winid)
    lnum = mousepos.line
  else
    winid = vim.api.nvim_get_current_win()
    bufnr = vim.api.nvim_get_current_buf()
    lnum = vim.api.nvim_win_get_cursor(winid)[1]
  end

  if not normal_buffer(bufnr) then
    return nil
  end

  local line_count = vim.api.nvim_buf_line_count(bufnr)
  lnum = math.max(1, math.min(lnum or 1, line_count))

  return {
    winid = winid,
    bufnr = bufnr,
    lnum = lnum,
  }
end

local function load_dap()
  if not package.loaded["dap"] then
    local ok, lazy = pcall(require, "lazy")
    if ok then
      pcall(lazy.load, { plugins = { "nvim-dap" } })
    end
  end

  local ok, dap = pcall(require, "dap")
  if not ok then
    notify("nvim-dap is not available", vim.log.levels.ERROR)
    return nil
  end

  return dap
end

M.load_dap = load_dap

local function load_dapui()
  load_dap()

  local ok, dapui = pcall(require, "dapui")
  if not ok then
    notify("nvim-dap-ui is not available", vim.log.levels.ERROR)
    return nil
  end

  return dapui
end

local function dap_session()
  local dap = package.loaded["dap"]
  if not dap or not dap.session then
    return nil
  end

  return dap.session()
end

local function button(callback, label)
  return table.concat({
    "%@v:lua.",
    callback,
    "@",
    " ",
    label,
    " ",
    "%T",
  })
end

function M.active()
  return dap_session() ~= nil
end

function M.session_label()
  local session = dap_session()
  if not session then
    return ""
  end

  local name = session.config and session.config.name or "active"
  return "DAP " .. name
end

function M.define_signs()
  vim.fn.sign_define("DapBreakpoint", { text = "B", texthl = "DiagnosticSignError", numhl = "DiagnosticSignError" })
  vim.fn.sign_define(
    "DapBreakpointCondition",
    { text = "C", texthl = "DiagnosticSignWarn", numhl = "DiagnosticSignWarn" }
  )
  vim.fn.sign_define("DapLogPoint", { text = "L", texthl = "DiagnosticSignInfo", numhl = "DiagnosticSignInfo" })
  vim.fn.sign_define("DapStopped", { text = ">", texthl = "DiagnosticSignHint", numhl = "DiagnosticSignHint" })
  vim.fn.sign_define(
    "DapBreakpointRejected",
    { text = "R", texthl = "DiagnosticSignWarn", numhl = "DiagnosticSignWarn" }
  )
end

function M.toggle_breakpoint(args)
  local ctx = source_context(args)
  if not ctx then
    return
  end

  local dap = load_dap()
  if not dap then
    return
  end

  vim.api.nvim_win_call(ctx.winid, function()
    pcall(vim.api.nvim_win_set_cursor, ctx.winid, { ctx.lnum, 0 })

    local click = type(args) == "table" and args or {}
    if click.button == "r" then
      local condition = vim.fn.input("Breakpoint condition: ")
      if condition ~= "" then
        dap.set_breakpoint(condition)
      end
      return
    end

    if click.button == "m" then
      local message = vim.fn.input("Log point message: ")
      if message ~= "" then
        dap.set_breakpoint(nil, nil, message)
      end
      return
    end

    dap.toggle_breakpoint()
  end)
end

function M.file_winbar_prefix()
  local chunks = {
    "%#TabLine#",
    " DAP ",
  }

  if M.active() then
    vim.list_extend(chunks, {
      button("DebugContinue", "Cont"),
      button("DebugStepOver", "Over"),
      button("DebugStepInto", "Into"),
      button("DebugStepOut", "Out"),
      button("DebugRepl", "REPL"),
      button("DebugRestart", "Restart"),
      button("DebugStop", "Stop"),
      button("DebugToggleUI", "UI"),
      " | ",
    })
  else
    for _, action in ipairs(require("appdev.integrations.ui").inactive_buttons()) do
      chunks[#chunks + 1] = button(action.callback, action.label)
    end

    vim.list_extend(chunks, {
      button("DebugToggleUI", "UI"),
      " | ",
    })
  end

  return table.concat(chunks)
end

function M.refresh()
  for _, winid in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_is_valid(winid) then
      local bufnr = vim.api.nvim_win_get_buf(winid)
      if normal_buffer(bufnr) then
        pcall(vim.api.nvim_win_call, winid, function()
          require("config.splitview").set_file_winbar()
        end)
      end
    end
  end

  if package.loaded["lualine"] then
    require("lualine").refresh()
  else
    vim.cmd.redrawstatus()
  end
end

function M.refresh_later()
  vim.schedule(function()
    M.refresh()
  end)
end

function M.setup_click_handlers()
  if handlers_registered then
    return
  end
  handlers_registered = true

  _G.ScDapBreakpoint = function(_, _, button, _)
    require("config.debug_ui").toggle_breakpoint({
      button = button,
      mousepos = vim.fn.getmousepos(),
    })
  end

  _G.DebugContinue = function()
    local dap = load_dap()
    if dap then
      dap.continue()
    end
  end

  _G.DebugStepOver = function()
    local dap = load_dap()
    if dap then
      dap.step_over()
    end
  end

  _G.DebugStepInto = function()
    local dap = load_dap()
    if dap then
      dap.step_into()
    end
  end

  _G.DebugStepOut = function()
    local dap = load_dap()
    if dap then
      dap.step_out()
    end
  end

  _G.DebugRestart = function()
    local dap = load_dap()
    if not dap then
      return
    end

    if dap.restart then
      dap.restart()
    else
      dap.run_last()
    end
  end

  _G.DebugStop = function()
    local dap = load_dap()
    if dap then
      dap.terminate()
    end
  end

  _G.DebugRepl = function()
    local dap = load_dap()
    if dap then
      dap.repl.toggle()
    end
  end

  _G.DebugToggleUI = function()
    local dapui = load_dapui()
    if dapui then
      dapui.toggle()
    end
  end

  require("appdev.integrations.ui").setup_click_handlers()
end

function M.setup(dap)
  M.define_signs()
  M.setup_click_handlers()

  if listeners_registered then
    return
  end
  listeners_registered = true

  dap.listeners.after.event_initialized["debug_ui"] = function()
    M.refresh_later()
  end
  dap.listeners.after.event_stopped["debug_ui"] = function()
    M.refresh_later()
  end
  dap.listeners.after.event_continued["debug_ui"] = function()
    M.refresh_later()
  end
  dap.listeners.before.event_terminated["debug_ui"] = function()
    M.refresh_later()
  end
  dap.listeners.before.event_exited["debug_ui"] = function()
    M.refresh_later()
  end
end

return M
