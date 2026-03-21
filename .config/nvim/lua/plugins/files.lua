return {
  {
    "nvim-tree/nvim-tree.lua",
    cmd = { "NvimTreeToggle", "NvimTreeFocus", "NvimTreeFindFile" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local function build_tree_menu(node, tree_win)
        local api = require("nvim-tree.api")

        local function with_tree_context(fn)
          return function()
            if not vim.api.nvim_win_is_valid(tree_win) then
              return
            end

            vim.api.nvim_win_call(tree_win, function()
              fn(node)
            end)
          end
        end

        return {
          { label = "Open", action = with_tree_context(api.node.open.edit) },
          { label = "Open Vertical Split", action = with_tree_context(api.node.open.vertical) },
          { label = "Open Horizontal Split", action = with_tree_context(api.node.open.horizontal) },
          { label = "Open in New Tab", action = with_tree_context(api.node.open.tab) },
          { label = "Create", action = with_tree_context(api.fs.create) },
          { label = "Rename", action = with_tree_context(api.fs.rename) },
          { label = "Delete", action = with_tree_context(api.fs.remove) },
          { label = "Trash", action = with_tree_context(api.fs.trash) },
          { label = "Cut", action = with_tree_context(api.fs.cut) },
          { label = "Copy", action = with_tree_context(api.fs.copy.node) },
          { label = "Paste", action = with_tree_context(api.fs.paste) },
          { label = "Copy Absolute Path", action = with_tree_context(api.fs.copy.absolute_path) },
          { label = "Copy Relative Path", action = with_tree_context(api.fs.copy.relative_path) },
          { label = "Refresh", action = with_tree_context(function() api.tree.reload() end) },
        }
      end

      local function open_context_menu()
        local api = require("nvim-tree.api")

        vim.cmd.exec('"normal! \\<RightMouse>"')

        local mouse = vim.fn.getmousepos()
        local buf = mouse.winid ~= 0 and vim.api.nvim_win_get_buf(mouse.winid) or 0

        if buf == 0 or vim.bo[buf].filetype ~= "NvimTree" then
          return
        end

        local node = api.tree.get_node_under_cursor()
        if not node then
          return
        end

        local items = build_tree_menu(node, mouse.winid)
        vim.ui.select(items, {
          prompt = "Tree Actions",
          format_item = function(item)
            return item.label
          end,
        }, function(choice)
          if choice then
            choice.action()
          end
        end)
      end

      local function on_attach(bufnr)
        local api = require("nvim-tree.api")

        local function opts(desc)
          return {
            desc = "nvim-tree: " .. desc,
            buffer = bufnr,
            noremap = true,
            silent = true,
            nowait = true,
          }
        end

        api.map.on_attach.default(bufnr)
        vim.keymap.set("n", "<RightMouse>", open_context_menu, opts("Context Menu"))
        vim.keymap.set("n", "M", open_context_menu, opts("Context Menu"))
      end

      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1

      require("nvim-tree").setup({
        on_attach = on_attach,
        hijack_netrw = true,
        hijack_cursor = true,
        sync_root_with_cwd = true,
        respect_buf_cwd = true,
        update_focused_file = {
          enable = true,
          update_root = true,
        },
        view = {
          width = 34,
          side = "left",
          preserve_window_proportions = true,
        },
        renderer = {
          group_empty = true,
          highlight_git = true,
          highlight_opened_files = "name",
          indent_markers = {
            enable = true,
          },
        },
        filters = {
          dotfiles = false,
          custom = { "^.git$" },
        },
        git = {
          enable = true,
          ignore = false,
          timeout = 2000,
        },
        diagnostics = {
          enable = true,
          show_on_dirs = false,
        },
        actions = {
          open_file = {
            resize_window = true,
            quit_on_open = false,
            window_picker = {
              enable = true,
            },
          },
        },
      })
    end,
  },
}
