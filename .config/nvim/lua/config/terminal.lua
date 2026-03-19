local M = {}

local function open_terminal(cmd)
  if cmd then
    vim.cmd(cmd)
  end
  vim.cmd.terminal()
  vim.cmd.startinsert()
end

function M.open_floatless()
  open_terminal()
end

function M.open_horizontal()
  open_terminal("split")
end

function M.open_vertical()
  open_terminal("vsplit")
end

function M.close_current()
  vim.cmd.close()
end

function M.set_terminal_winbar()
  vim.wo.winbar = table.concat({
    "%#TabLine#",
    "%@v:lua.TerminalOpenHorizontal@",
    " 󰤻 Horizontal ",
    "%T",
    "%@v:lua.TerminalOpenVertical@",
    " 󰤼 Vertical ",
    "%T",
    "%@v:lua.TerminalCloseCurrent@",
    " 󰅖 Close ",
    "%T",
    "%*",
  })
end

function M.setup_click_handlers()
  _G.TerminalOpenHorizontal = function()
    require("config.terminal").open_horizontal()
  end

  _G.TerminalOpenVertical = function()
    require("config.terminal").open_vertical()
  end

  _G.TerminalCloseCurrent = function()
    require("config.terminal").close_current()
  end
end

return M
