local group = vim.api.nvim_create_augroup("JosephNeovim", { clear = true })

require("config.terminal").setup_click_handlers()
require("config.splitview").setup_click_handlers()
require("config.diagnostics").setup_click_handlers()

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  desc = "Highlight yanked text",
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 120 })
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "markdown", "rst", "gitcommit", "text" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
    vim.opt_local.breakindent = true
    vim.opt_local.spell = true
    vim.opt_local.textwidth = 88
    vim.opt_local.colorcolumn = ""
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "yaml", "yml" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = group,
  pattern = { "c", "cpp", "objc", "objcpp" },
  callback = function()
    vim.opt_local.tabstop = 4
    vim.opt_local.shiftwidth = 4
    vim.opt_local.expandtab = true
  end,
})

vim.api.nvim_create_autocmd("LspAttach", {
  group = group,
  callback = function(args)
    local bufnr = args.buf
    local map = function(mode, lhs, rhs, desc)
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
    end

    map("n", "gd", vim.lsp.buf.definition, "Goto definition")
    map("n", "gD", vim.lsp.buf.declaration, "Goto declaration")
    map("n", "gr", vim.lsp.buf.references, "Goto references")
    map("n", "gi", vim.lsp.buf.implementation, "Goto implementation")
    map("n", "K", vim.lsp.buf.hover, "Hover docs")
    map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
    map("n", "<leader>ca", vim.lsp.buf.code_action, "Code action")
    map("n", "[d", vim.diagnostic.goto_prev, "Previous diagnostic")
    map("n", "]d", vim.diagnostic.goto_next, "Next diagnostic")
    map("n", "<leader>df", function()
      vim.diagnostic.open_float(nil, { border = "rounded" })
    end, "Line diagnostics")
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = group,
  desc = "Configure terminal buffers",
  callback = function()
    vim.opt_local.number = false
    vim.opt_local.relativenumber = false
    vim.opt_local.signcolumn = "no"
    vim.opt_local.spell = false
    require("config.terminal").set_terminal_winbar()
    vim.cmd.startinsert()
  end,
})

vim.api.nvim_create_autocmd({ "BufEnter", "BufFilePost", "BufModifiedSet", "BufWinEnter", "WinEnter" }, {
  group = group,
  desc = "Configure file buffer winbar",
  callback = function(args)
    local bufnr = args.buf
    local bt = vim.bo[bufnr].buftype
    local ft = vim.bo[bufnr].filetype

    if bt ~= "" or ft == "NvimTree" then
      return
    end

    require("config.diagnostics").sync_to_buffer(bufnr)
    require("config.splitview").set_file_winbar()
  end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter" }, {
  group = group,
  desc = "Configure diagnostics window winbar",
  callback = function(args)
    local bufnr = args.buf
    if vim.bo[bufnr].filetype ~= "trouble" then
      return
    end

    local winid = vim.fn.bufwinid(bufnr)
    if winid ~= -1 then
      require("config.diagnostics").set_trouble_winbar(winid)
    end
  end,
})

vim.api.nvim_create_autocmd({ "BufWinEnter", "WinEnter", "WinNew" }, {
  group = group,
  desc = "Configure Git popup winbar",
  callback = function()
    vim.schedule(function()
      for _, winid in ipairs(vim.api.nvim_list_wins()) do
        require("config.gitinspect").set_popup_winbar(winid)
      end
    end)
  end,
})

vim.api.nvim_create_autocmd({ "BufWinLeave", "WinClosed" }, {
  group = group,
  desc = "Refresh statusline after diagnostics window closes",
  callback = function()
    vim.schedule(function()
      if package.loaded["lualine"] then
        require("lualine").refresh()
      else
        vim.cmd.redrawstatus()
      end
    end)
  end,
})

vim.api.nvim_create_autocmd("VimEnter", {
  group = group,
  desc = "Restore sessions and open tree for workspace starts",
  callback = function()
    local function load_plugin(plugin)
      local ok, lazy = pcall(require, "lazy")
      if ok then
        lazy.load({ plugins = { plugin } })
      end
    end

    local argc = vim.fn.argc()
    local tree_mode = false
    local restore_session = false

    if argc == 0 then
      tree_mode = true
      restore_session = true
    elseif argc == 1 then
      local arg0 = vim.fn.argv(0)
      if arg0 ~= "" and vim.fn.isdirectory(arg0) == 1 then
        tree_mode = true
        restore_session = true
      end
    end

    if restore_session then
      load_plugin("persistence.nvim")
      local ok, persistence = pcall(require, "persistence")
      if ok then
        persistence.load()
      end
    end

    if tree_mode then
      load_plugin("nvim-tree.lua")
      local ok, api = pcall(require, "nvim-tree.api")
      if ok and not api.tree.is_visible() then
        api.tree.open({
          focus = true,
        })
      end
    end
  end,
})

vim.diagnostic.config({
  severity_sort = true,
  float = {
    border = "rounded",
    source = "if_many",
  },
  signs = true,
  underline = true,
  virtual_text = {
    spacing = 2,
    prefix = "*",
  },
})
