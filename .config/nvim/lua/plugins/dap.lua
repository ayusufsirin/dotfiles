return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "williamboman/mason.nvim",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "mfussenegger/nvim-dap-python",
    },
    keys = {
      { "<leader>db", mode = "n", desc = "Toggle breakpoint" },
      { "<leader>dc", mode = "n", desc = "Continue debugger" },
      { "<leader>do", mode = "n", desc = "Step over" },
      { "<leader>di", mode = "n", desc = "Step into" },
      { "<leader>dO", mode = "n", desc = "Step out" },
      { "<leader>du", mode = "n", desc = "Toggle DAP UI" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")

      require("nvim-dap-virtual-text").setup({
        commented = true,
      })

      dapui.setup({
        floating = {
          border = "rounded",
        },
      })

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated["dapui_config"] = function()
        dapui.close()
      end
      dap.listeners.before.event_exited["dapui_config"] = function()
        dapui.close()
      end

      vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
      vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue debugger" })
      vim.keymap.set("n", "<leader>do", dap.step_over, { desc = "Step over" })
      vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step into" })
      vim.keymap.set("n", "<leader>dO", dap.step_out, { desc = "Step out" })
      vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })

      local debugpy = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
      if vim.fn.executable(debugpy) == 1 then
        require("dap-python").setup(debugpy)
      end

      dap.adapters.codelldb = function(callback, config)
        local registry_ok, registry = pcall(require, "mason-registry")
        if not registry_ok then
          return
        end

        local package = registry.get_package("codelldb")
        if not package:is_installed() then
          return
        end

        local extension_path = package:get_install_path() .. "/extension"
        local adapter_path = extension_path .. "/adapter/codelldb"
        local library_path = extension_path .. "/lldb/lib/liblldb.so"

        if vim.fn.has("mac") == 1 then
          library_path = extension_path .. "/lldb/lib/liblldb.dylib"
        elseif vim.fn.has("win32") == 1 then
          library_path = extension_path .. "/lldb/bin/liblldb.dll"
        end

        callback({
          type = "server",
          port = "${port}",
          executable = {
            command = adapter_path,
            args = { "--liblldb", library_path, "--port", "${port}" },
          },
        })
      end

      local cpp_config = {
        {
          name = "Launch file",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
        },
      }

      dap.configurations.c = cpp_config
      dap.configurations.cpp = cpp_config
    end,
  },
}
