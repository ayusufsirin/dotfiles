return {
  {
    "neovim/nvim-lspconfig",
    version = "v1.8.0",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "WhoIsSethDaniel/mason-tool-installer.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "j-hui/fidget.nvim",
      "b0o/schemastore.nvim",
    },
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()
      local lspconfig = require("lspconfig")

      require("mason").setup({
        ui = {
          border = "rounded",
        },
      })

      require("fidget").setup({})

      require("mason-tool-installer").setup({
        ensure_installed = {
          "clangd",
          "clang-format",
          "codelldb",
          "debugpy",
          "lua-language-server",
          "markdownlint-cli2",
          "marksman",
          "prettier",
          "pyright",
          "ruff",
          "shellcheck",
          "shfmt",
          "stylua",
          "yaml-language-server",
        },
        auto_update = false,
        run_on_start = true,
      })

      local on_attach = function(client, bufnr)
        if client.name == "clangd" then
          client.server_capabilities.semanticTokensProvider = nil
        end

        vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
      end

      local servers = {
        clangd = {
          capabilities = capabilities,
          on_attach = on_attach,
          cmd = {
            "clangd",
            "--background-index",
            "--clang-tidy",
            "--completion-style=detailed",
            "--header-insertion=never",
          },
        },
        lua_ls = {
          capabilities = capabilities,
          on_attach = on_attach,
          settings = {
            Lua = {
              diagnostics = {
                globals = { "vim" },
              },
              workspace = {
                checkThirdParty = false,
                library = vim.api.nvim_get_runtime_file("", true),
              },
              telemetry = {
                enable = false,
              },
            },
          },
        },
        marksman = {
          capabilities = capabilities,
          on_attach = on_attach,
        },
        pyright = {
          capabilities = capabilities,
          on_attach = on_attach,
        },
        yamlls = {
          capabilities = capabilities,
          on_attach = on_attach,
          settings = {
            yaml = {
              keyOrdering = false,
              format = {
                enable = true,
              },
              validate = true,
              schemaStore = {
                enable = false,
                url = "",
              },
              schemas = require("schemastore").yaml.schemas(),
            },
            redhat = {
              telemetry = {
                enabled = false,
              },
            },
          },
        },
      }

      for server_name, server in pairs(servers) do
        server.capabilities = vim.tbl_deep_extend("force", {}, capabilities, server.capabilities or {})
        server.on_attach = server.on_attach or on_attach
        lspconfig[server_name].setup(server)
      end
    end,
  },
}
