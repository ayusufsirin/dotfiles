return {
  {
    "ellisonleao/gruvbox.nvim",
    priority = 1000,
    config = function()
      require("gruvbox").setup({
        contrast = "hard",
        transparent_mode = false,
        italic = {
          comments = true,
          emphasis = true,
          strings = false,
          operators = false,
          folds = true,
        },
      })

      vim.cmd.colorscheme("gruvbox")
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("lualine").setup({
        options = {
          theme = "gruvbox",
          globalstatus = true,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
      })
    end,
  },
  {
    "akinsho/bufferline.nvim",
    version = "*",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({
        options = {
          mode = "buffers",
          diagnostics = "nvim_lsp",
          always_show_bufferline = true,
          separator_style = "slant",
          show_close_icon = false,
          show_buffer_close_icons = true,
          close_command = "bdelete! %d",
          right_mouse_command = "bdelete! %d",
          offsets = {
            {
              filetype = "NvimTree",
              text = "Project",
              highlight = "Directory",
              text_align = "left",
              separator = true,
            },
          },
        },
      })
    end,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = function()
      require("which-key").setup({
        preset = "modern",
        win = {
          border = "rounded",
        },
      })
    end,
  },
}
