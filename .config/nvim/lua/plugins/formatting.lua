return {
  {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("conform").setup({
        notify_on_error = false,
        format_on_save = function(bufnr)
          local ignore = { rst = true }
          if ignore[vim.bo[bufnr].filetype] then
            return nil
          end

          return {
            timeout_ms = 2000,
            lsp_format = "fallback",
          }
        end,
        formatters_by_ft = {
          c = { "clang_format" },
          cpp = { "clang_format" },
          css = { "prettier" },
          html = { "prettier" },
          javascript = { "prettier" },
          json = { "prettier" },
          lua = { "stylua" },
          markdown = { "prettier" },
          python = { "ruff_fix", "ruff_format" },
          rst = {},
          sh = { "shfmt" },
          yaml = { "prettier" },
        },
      })

      vim.api.nvim_create_user_command("Format", function()
        require("conform").format({
          async = false,
          lsp_format = "fallback",
        })
      end, {})
    end,
  },
  {
    "mfussenegger/nvim-lint",
    event = { "BufReadPost", "BufNewFile", "InsertLeave" },
    config = function()
      local lint = require("lint")

      lint.linters_by_ft = {
        markdown = { "markdownlint-cli2" },
        python = { "ruff" },
        rst = { "rstcheck" },
        sh = { "shellcheck" },
      }

      vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
        group = vim.api.nvim_create_augroup("JosephLint", { clear = true }),
        callback = function()
          lint.try_lint()
        end,
      })
    end,
  },
}
