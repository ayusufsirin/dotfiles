local M = {}

local function git()
  return require("gitsigns")
end

local actions = {
  {
    label = "Preview hunk",
    run = function()
      git().preview_hunk()
    end,
  },
  {
    label = "Blame line",
    run = function()
      git().blame_line({ full = true })
    end,
  },
  {
    label = "Toggle inline blame",
    run = function()
      git().toggle_current_line_blame()
    end,
  },
}

function M.open_menu(args)
  if type(args) ~= "table" then
    args = nil
  end

  local mousepos = args and args.mousepos or vim.fn.getmousepos()
  if mousepos and mousepos.winid and mousepos.line then
    pcall(vim.api.nvim_win_set_cursor, mousepos.winid, { mousepos.line, 0 })
  end

  if not vim.b.gitsigns_head then
    vim.notify("No Git metadata for the current buffer", vim.log.levels.INFO)
    return
  end

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
end

return M
