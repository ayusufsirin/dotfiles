return {
  {
    "folke/trouble.nvim",
    cmd = { "Trouble", "TroubleToggle", "TroubleClose" },
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local function diagnostics_mode(title, severity)
        return {
          mode = "diagnostics",
          desc = title,
          focus = false,
          follow = false,
          pinned = false,
          restore = false,
          warn_no_results = false,
          open_no_results = false,
          auto_preview = false,
          filter = {
            severity = severity,
          },
          win = {
            type = "split",
            position = "bottom",
            size = 10,
          },
        }
      end

      require("trouble").setup({
        focus = true,
        auto_preview = false,
        modes = {
          buffer_errors = diagnostics_mode("Buffer Errors", vim.diagnostic.severity.ERROR),
          buffer_warnings = diagnostics_mode("Buffer Warnings", vim.diagnostic.severity.WARN),
          buffer_info = diagnostics_mode("Buffer Info", vim.diagnostic.severity.INFO),
          buffer_hints = diagnostics_mode("Buffer Hints", vim.diagnostic.severity.HINT),
        },
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
