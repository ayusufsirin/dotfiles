return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    lazy = false,
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "master",
      },
    },
    config = function()
      local offline = require("config.offline")
      if offline.enabled() then
        require("nvim-treesitter.install").prefer_git = true
      end
      local ensure_installed = offline.parsers
      if vim.env.NVIM_OFFLINE_PRIME == "1" then
        ensure_installed = {}
      end
      require("nvim-treesitter.configs").setup({
        ensure_installed = ensure_installed,
        highlight = { enable = true },
        indent = { enable = true },
        incremental_selection = {
          enable = true,
          keymaps = {
            init_selection = "<C-space>",
            node_incremental = "<C-space>",
            node_decremental = "<bs>",
          },
        },
        textobjects = {
          select = {
            enable = true,
            lookahead = true,
            keymaps = {
              ["af"] = "@function.outer",
              ["if"] = "@function.inner",
              ["ac"] = "@class.outer",
              ["ic"] = "@class.inner",
            },
          },
        },
      })
    end,
  },
}
