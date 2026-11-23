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

      -- The frozen master branch supports Neovim through 0.11. On 0.12,
      -- prefer Neovim's bundled Markdown queries so its rewritten Tree-sitter
      -- query engine does not execute the legacy Markdown directives.
      if vim.fn.has("nvim-0.12") == 1 then
        for _, language in ipairs({ "markdown", "markdown_inline" }) do
          for _, query_name in ipairs({ "highlights", "injections", "folds" }) do
            local query_path = table.concat({ vim.env.VIMRUNTIME, "queries", language, query_name .. ".scm" }, "/")
            if vim.fn.filereadable(query_path) == 1 then
              local query = table.concat(vim.fn.readfile(query_path), "\n")
              vim.treesitter.query.set(language, query_name, query)
            end
          end
        end

        -- shortcut: adapt the frozen plugin's downcase! on 0.12; remove when migrating to main.
        vim.treesitter.query.add_directive("downcase!", function(match, _, bufnr, predicate, metadata)
          local id = predicate[2]
          local nodes = match[id]
          if not nodes or #nodes == 0 then
            return
          end
          local text = vim.treesitter.get_node_text(nodes[#nodes], bufnr, { metadata = metadata[id] }) or ""
          metadata[id] = metadata[id] or {}
          metadata[id].text = text:lower()
        end, { force = true })
      end

      if offline.enabled() then
        require("nvim-treesitter.install").prefer_git = true
        offline.normalize_treesitter_git_urls()
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
