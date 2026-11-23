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
      local statusline = require("config.statusline")

      require("lualine").setup({
        options = {
          theme = "gruvbox",
          globalstatus = true,
          component_separators = { left = "", right = "" },
          section_separators = { left = "", right = "" },
        },
        sections = {
          lualine_a = { "mode" },
          lualine_b = { "branch", "diff" },
          lualine_c = { statusline.filename() },
          lualine_x = {
            statusline.diagnostic_component("error"),
            statusline.diagnostic_component("warn"),
            statusline.diagnostic_component("info"),
            statusline.diagnostic_component("hint"),
            statusline.debug_component(),
            "filetype",
          },
          lualine_y = { "progress" },
          lualine_z = { "location" },
        },
        inactive_sections = {
          lualine_a = {},
          lualine_b = {},
          lualine_c = { statusline.filename() },
          lualine_x = { "location" },
          lualine_y = {},
          lualine_z = {},
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
