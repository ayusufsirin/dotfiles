local M = {}

local function telescope_pick_in_current_win()
  local ok, telescope = pcall(require, "telescope.builtin")
  if not ok then
    vim.notify("Telescope is not available", vim.log.levels.ERROR)
    return
  end

  telescope.find_files({
    hidden = true,
  })
end

local function current_file()
  local path = vim.api.nvim_buf_get_name(0)
  if path == "" then
    return nil
  end
  return vim.fn.fnameescape(path)
end

function M.open_horizontal()
  local path = current_file()
  if path then
    vim.cmd("split " .. path)
  else
    vim.cmd.split()
  end
end

function M.open_vertical()
  local path = current_file()
  if path then
    vim.cmd("vsplit " .. path)
  else
    vim.cmd.vsplit()
  end
end

function M.close_current()
  vim.cmd.close()
end

function M.next_buffer()
  vim.cmd.bnext()
end

function M.prev_buffer()
  vim.cmd.bprevious()
end

function M.pick_current()
  telescope_pick_in_current_win()
end

function M.pick_horizontal()
  vim.cmd.split()
  telescope_pick_in_current_win()
end

function M.pick_vertical()
  vim.cmd.vsplit()
  telescope_pick_in_current_win()
end

function M.set_file_winbar()
  vim.wo.winbar = table.concat({
    "%#TabLine#",
    "%@v:lua.FilePrevBuffer@",
    " 󰒮 Prev ",
    "%T",
    "%@v:lua.FileNextBuffer@",
    " 󰒭 Next ",
    "%T",
    "%@v:lua.FilePickCurrent@",
    " 󰱼 Pick ",
    "%T",
    "%#TabLineSel#",
    " %<%t %m ",
    "%#TabLine#",
    "%=",
    "%@v:lua.FileOpenHorizontal@",
    " 󰤻 Split H ",
    "%T",
    "%@v:lua.FileOpenVertical@",
    " 󰤼 Split V ",
    "%T",
    "%@v:lua.FilePickHorizontal@",
    " 󱂬 Pick H ",
    "%T",
    "%@v:lua.FilePickVertical@",
    " 󱇙 Pick V ",
    "%T",
    "%@v:lua.FileCloseCurrent@",
    " 󰅖 Close ",
    "%T",
    "%*",
  })
end

function M.setup_click_handlers()
  _G.FilePrevBuffer = function()
    require("config.splitview").prev_buffer()
  end

  _G.FileNextBuffer = function()
    require("config.splitview").next_buffer()
  end

  _G.FilePickCurrent = function()
    require("config.splitview").pick_current()
  end

  _G.FileOpenHorizontal = function()
    require("config.splitview").open_horizontal()
  end

  _G.FileOpenVertical = function()
    require("config.splitview").open_vertical()
  end

  _G.FilePickHorizontal = function()
    require("config.splitview").pick_horizontal()
  end

  _G.FilePickVertical = function()
    require("config.splitview").pick_vertical()
  end

  _G.FileCloseCurrent = function()
    require("config.splitview").close_current()
  end
end

return M
