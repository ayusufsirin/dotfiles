return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    branch = "v3.x",
    cmd = { "Neotree" },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
      "nvim-tree/nvim-web-devicons",
    },
    config = function()
      require("neo-tree").setup({
        close_if_last_window = false,
        popup_border_style = "rounded",
        enable_git_status = true,
        enable_diagnostics = false,
        sources = { "filesystem", "buffers", "git_status" },
        source_selector = {
          winbar = true,
          statusline = false,
        },
        default_component_configs = {
          git_status = {
            symbols = {
              added = "A",
              modified = "M",
              deleted = "D",
              renamed = "R",
              untracked = "?",
              ignored = "I",
              unstaged = "U",
              staged = "S",
              conflict = "!",
            },
          },
        },
        git_status = {
          window = {
            position = "right",
            width = 42,
            mappings = {
              ["<cr>"] = "open",
              ["s"] = "open_split",
              ["v"] = "open_vsplit",
              ["t"] = "open_tabnew",
              ["R"] = "refresh",
              ["q"] = "close_window",
              ["a"] = "git_add_file",
              ["u"] = "git_unstage_file",
              ["r"] = "git_revert_file",
              ["A"] = "git_add_all",
              ["C"] = "git_commit",
              ["P"] = "git_push",
            },
          },
        },
      })
    end,
  },
}
