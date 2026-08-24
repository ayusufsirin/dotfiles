return {
  {
    "nvim-treesitter/nvim-treesitter",
    branch = "master",
    build = function()
      if require("config.offline").enabled() then
        require("nvim-treesitter.install").prefer_git = true
      end
      vim.cmd("TSUpdate")
    end,
    lazy = false,
    dependencies = {
      {
        "nvim-treesitter/nvim-treesitter-textobjects",
        branch = "master",
      },
    },
    config = function()
      if require("config.offline").enabled() then
        require("nvim-treesitter.install").prefer_git = true
      end
      require("nvim-treesitter.configs").setup({
        ensure_installed = require("config.offline").parsers,
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
