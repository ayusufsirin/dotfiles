local M = {}

local MENU_NS = vim.api.nvim_create_namespace("GitInspectMenu")
local menu_state = {
  bufnr = nil,
  winid = nil,
}

local function git()
  return require("gitsigns")
end

local function is_gitsigns_attached(bufnr)
  if not bufnr or bufnr == 0 or not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local ok_head, head = pcall(function()
    return vim.b[bufnr].gitsigns_head
  end)
  if ok_head and head then
    return true
  end

  local ok_status, status = pcall(function()
    return vim.b[bufnr].gitsigns_status_dict
  end)
  return ok_status and type(status) == "table"
end

local function line_has_gitsign(bufnr, lnum)
  if not bufnr or not lnum or not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  local row = lnum - 1
  local marks = vim.api.nvim_buf_get_extmarks(bufnr, -1, { row, 0 }, { row, -1 }, {
    type = "sign",
    details = true,
  })

  for _, mark in ipairs(marks) do
    local details = mark[4]
    local sign_name = details and details.sign_name or ""
    if sign_name:match("^GitSigns") then
      return true
    end
  end

  return false
end

local function context_from_args(args)
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

  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
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

local function close_menu()
  if menu_state.winid and vim.api.nvim_win_is_valid(menu_state.winid) then
    pcall(vim.api.nvim_win_close, menu_state.winid, true)
  end

  menu_state.bufnr = nil
  menu_state.winid = nil
end

local function in_source_window(winid, lnum, fn)
  return function()
    if not winid or not vim.api.nvim_win_is_valid(winid) then
      return
    end

    local bufnr = vim.api.nvim_win_get_buf(winid)
    if not is_gitsigns_attached(bufnr) then
      return
    end

    local ok, err = pcall(vim.api.nvim_win_call, winid, function()
      pcall(vim.api.nvim_win_set_cursor, winid, { lnum, 0 })
      fn()
    end)

    if not ok then
      vim.notify(err, vim.log.levels.ERROR, { title = "Git actions" })
    end
  end
end

local function build_actions(winid, lnum)
  return {
    {
      key = "p",
      label = "Preview hunk",
      hint = "Open diff popup",
      run = in_source_window(winid, lnum, function()
        git().preview_hunk()
      end),
    },
    {
      key = "b",
      label = "Blame line",
      hint = "Show commit details",
      run = in_source_window(winid, lnum, function()
        git().blame_line({ full = true })
      end),
    },
    {
      key = "t",
      label = "Toggle inline blame",
      hint = "Show or hide blame text",
      run = in_source_window(winid, lnum, function()
        git().toggle_current_line_blame()
      end),
    },
  }
end

local function apply_action(action)
  if not action then
    return
  end

  close_menu()
  vim.schedule(action.run)
end

local function action_for_line(actions, line)
  return actions[line]
end

local function action_for_key(actions, key)
  for _, action in ipairs(actions) do
    if action.key == key then
      return action
    end
  end
end

local function render_menu(bufnr, actions, title)
  local lines = {}
  local width = vim.api.nvim_strwidth(title)

  for _, action in ipairs(actions) do
    local line = string.format("[%s] %s", action.key:upper(), action.label)
    if action.hint then
      line = string.format("%-24s %s", line, action.hint)
    end
    width = math.max(width, vim.api.nvim_strwidth(line))
    lines[#lines + 1] = line
  end

  vim.bo[bufnr].modifiable = true
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  vim.bo[bufnr].modifiable = false

  for index, action in ipairs(actions) do
    vim.api.nvim_buf_add_highlight(bufnr, MENU_NS, "Special", index - 1, 1, 2)
    vim.api.nvim_buf_add_highlight(bufnr, MENU_NS, "Title", index - 1, 4, 4 + #action.label)
  end

  return width
end

local function open_floating_menu(ctx, actions)
  close_menu()

  local bufnr = vim.api.nvim_create_buf(false, true)
  local title = string.format(" Git line %d ", ctx.lnum)
  local width = render_menu(bufnr, actions, title)
  local height = #actions

  local menu_winid = vim.api.nvim_open_win(bufnr, false, {
    relative = "cursor",
    row = 1,
    col = 1,
    width = width + 2,
    height = height,
    border = "rounded",
    style = "minimal",
    title = title,
    title_pos = "center",
    noautocmd = true,
    zindex = 160,
  })

  menu_state.bufnr = bufnr
  menu_state.winid = menu_winid

  vim.bo[bufnr].bufhidden = "wipe"
  vim.bo[bufnr].filetype = "gitinspect"

  vim.api.nvim_set_option_value("cursorline", true, { scope = "local", win = menu_winid })
  vim.api.nvim_set_option_value("winblend", 0, { scope = "local", win = menu_winid })
  vim.api.nvim_set_option_value("wrap", false, { scope = "local", win = menu_winid })

  local function choose_current()
    local line = vim.api.nvim_win_get_cursor(menu_winid)[1]
    apply_action(action_for_line(actions, line))
  end

  local function map(lhs, rhs)
    vim.keymap.set("n", lhs, rhs, { buffer = bufnr, nowait = true, silent = true })
  end

  map("<Esc>", close_menu)
  map("q", close_menu)
  map("<CR>", choose_current)
  map("<LeftMouse>", choose_current)

  for _, action in ipairs(actions) do
    map(action.key, function()
      apply_action(action)
    end)
    map(action.key:upper(), function()
      apply_action(action)
    end)
  end

  vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave" }, {
    buffer = bufnr,
    once = true,
    callback = close_menu,
  })

  vim.api.nvim_set_current_win(menu_winid)
  vim.api.nvim_win_set_cursor(menu_winid, { 1, 0 })
end

function M.open_menu(args)
  local ctx = context_from_args(args)
  if not ctx or not is_gitsigns_attached(ctx.bufnr) then
    return
  end

  if not line_has_gitsign(ctx.bufnr, ctx.lnum) then
    return
  end

  pcall(vim.api.nvim_win_set_cursor, ctx.winid, { ctx.lnum, 0 })

  local actions = build_actions(ctx.winid, ctx.lnum)
  local click = type(args) == "table" and args or {}

  if click.button == "r" then
    apply_action(action_for_key(actions, "b"))
    return
  end

  if click.button == "m" or (click.button == "l" and click.mods and click.mods:find("c")) then
    apply_action(action_for_key(actions, "t"))
    return
  end

  if click.button == "l" and click.clicks == 2 then
    apply_action(action_for_key(actions, "p"))
    return
  end

  open_floating_menu(ctx, actions)
end

function M.setup_click_handler()
  _G.ScGitLine = function(...)
    require("config.gitinspect").open_menu(select(1, ...))
  end

  _G.GitPopupClose = function(...)
    local args = select(1, ...)
    local ctx = context_from_args(args)
    local winid = ctx and ctx.winid or vim.fn.getmousepos().winid
    if winid == 0 then
      winid = vim.api.nvim_get_current_win()
    end

    require("config.gitinspect").close_popup(winid)
  end
end

function M.close_popup(winid)
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    return
  end

  local ok, popup_id = pcall(function()
    return vim.w[winid].gitsigns_preview
  end)
  if not ok or popup_id == nil then
    return
  end

  pcall(vim.api.nvim_win_close, winid, true)
end

function M.set_popup_winbar(winid)
  if not winid or not vim.api.nvim_win_is_valid(winid) then
    return
  end

  local ok, popup_id = pcall(function()
    return vim.w[winid].gitsigns_preview
  end)
  if not ok or popup_id == nil then
    return
  end

  local label = popup_id == "blame" and " Git Blame " or " Git Preview "
  local winbar = table.concat({
    "%#TabLine#",
    label,
    "%=",
    "%@v:lua.GitPopupClose@",
    " 󰅖 Close ",
    "%T",
    "%*",
  })

  vim.api.nvim_set_option_value("winbar", winbar, { scope = "local", win = winid })
end

return M
