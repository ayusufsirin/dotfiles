return {
  {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleToggle", "TroubleClose" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("trouble").setup({
        focus = true,
        auto_preview = false,
      })
    end,
  },
  {
    "folke/persistence.nvim",
    event = "BufReadPre",
    config = function()
      require("persistence").setup({
        dir = vim.fn.stdpath("state") .. "/sessions/",
        options = { "curdir", "tabpages", "winsize", "help", "globals" },
      })
    end,
  },
  {
    "ahmedkhalf/project.nvim",
    event = "VeryLazy",
    dependencies = { "nvim-telescope/telescope.nvim" },
    config = function()
      require("project_nvim").setup({
        manual_mode = false,
        detection_methods = { "lsp", "pattern" },
        patterns = {
          ".git",
          "Makefile",
          "CMakeLists.txt",
          "compile_commands.json",
          "pyproject.toml",
          "package.json",
          "go.mod",
          "Cargo.toml",
        },
        exclude_dirs = {
          "~/.cargo",
          "~/Downloads",
        },
        show_hidden = true,
        silent_chdir = true,
      })

      pcall(require("telescope").load_extension, "projects")
    end,
  },
}
