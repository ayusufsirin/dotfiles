local M = {}

local function git()
  return require("gitsigns")
end

local function in_source_window(winid, lnum, fn)
  return function()
    if not winid or not vim.api.nvim_win_is_valid(winid) then
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
      label = "Preview hunk",
      run = in_source_window(winid, lnum, function()
        git().preview_hunk()
      end),
    },
    {
      label = "Blame line",
      run = in_source_window(winid, lnum, function()
        git().blame_line({ full = true })
      end),
    },
    {
      label = "Toggle inline blame",
      run = in_source_window(winid, lnum, function()
        git().toggle_current_line_blame()
      end),
    },
  }
end

function M.open_menu(args)
  if type(args) ~= "table" then
    args = nil
  end

  local mousepos = args and args.mousepos
  local winid
  local bufnr
  local lnum

  if mousepos and mousepos.winid and mousepos.winid ~= 0 and vim.api.nvim_win_is_valid(mousepos.winid) then
    winid = mousepos.winid
    bufnr = vim.api.nvim_win_get_buf(winid)
    lnum = mousepos.line
    pcall(vim.api.nvim_win_set_cursor, winid, { lnum, 0 })
  else
    winid = vim.api.nvim_get_current_win()
    bufnr = vim.api.nvim_get_current_buf()
    lnum = vim.api.nvim_win_get_cursor(winid)[1]
  end

  if bufnr == 0 or not vim.b[bufnr].gitsigns_head then
    vim.notify("No Git metadata for the current buffer", vim.log.levels.INFO, { title = "Git actions" })
    return
  end

  local actions = build_actions(winid, lnum)
  local choices = vim.tbl_map(function(item)
    return item.label
  end, actions)

  vim.ui.select(choices, {
    prompt = "Git line actions",
  }, function(choice)
    if not choice then
      return
    end

    for _, item in ipairs(actions) do
      if item.label == choice then
        item.run()
        return
      end
    end
  end)
end

function M.setup_click_handler()
  _G.ScGitLine = function(...)
    require("config.gitinspect").open_menu(select(1, ...))
  end

  _G.GitPopupClose = function(...)
    local args = select(1, ...)
    local winid = nil

    if type(args) == "table" and args.mousepos and args.mousepos.winid and args.mousepos.winid ~= 0 then
      winid = args.mousepos.winid
    else
      winid = vim.api.nvim_get_current_win()
    end

    require("config.gitinspect").close_popup(winid)
  end
end

function M.close_popup(winid)
  if not winid or not vim.api.nvim_win_is_valid(winid) then
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
