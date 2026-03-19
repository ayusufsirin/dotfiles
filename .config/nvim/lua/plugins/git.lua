return {
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    cmd = { "Gitsigns" },
    config = function()
      require("gitsigns").setup({
        current_line_blame = true,
        current_line_blame_opts = {
          delay = 600,
          virt_text_pos = "eol",
          use_focus = true,
        },
        linehl = true,
        numhl = true,
        signs = {
          add = { text = "+" },
          change = { text = "~" },
          delete = { text = "_" },
          topdelete = { text = "^" },
          changedelete = { text = "~" },
        },
      })
    end,
  },
  {
    "luukvbaal/statuscol.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "lewis6991/gitsigns.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local builtin = require("statuscol.builtin")
      require("config.gitinspect").setup_click_handler()

      require("statuscol").setup({
        relculright = true,
        segments = {
          {
            text = { builtin.foldfunc },
            click = "v:lua.ScFa",
          },
          {
            sign = {
              name = { "DiagnosticSign.*", "GitSigns.*" },
              maxwidth = 2,
              colwidth = 1,
              auto = true,
              wrap = true,
            },
            click = "v:lua.ScSa",
          },
          {
            text = { builtin.lnumfunc },
            click = "v:lua.ScGitLine",
          },
        },
      })
    end,
  },
  {
    "stevearc/dressing.nvim",
    event = "VeryLazy",
    config = function()
      require("dressing").setup({})
    end,
  },
}
