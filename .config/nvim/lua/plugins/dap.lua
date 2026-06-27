return {
  {
    "mfussenegger/nvim-dap",
    dependencies = {
      "williamboman/mason.nvim",
      "rcarriga/nvim-dap-ui",
      "nvim-neotest/nvim-nio",
      "theHamsta/nvim-dap-virtual-text",
      "mfussenegger/nvim-dap-python",
      "jedrzejboczar/nvim-dap-cortex-debug",
    },
    keys = {
      { "<leader>db", mode = "n", desc = "Toggle breakpoint" },
      { "<leader>dc", mode = "n", desc = "Continue debugger" },
      { "<leader>do", mode = "n", desc = "Step over" },
      { "<leader>di", mode = "n", desc = "Step into" },
      { "<leader>dO", mode = "n", desc = "Step out" },
      { "<leader>du", mode = "n", desc = "Toggle DAP UI" },
      { "<leader>drb", mode = "n", desc = "Build ROS2 package" },
      { "<leader>drr", mode = "n", desc = "Run ROS2 node" },
      { "<leader>drp", mode = "n", desc = "Debug ROS2 Python node" },
      { "<leader>drc", mode = "n", desc = "Debug ROS2 C++ node" },
      { "<leader>dra", mode = "n", desc = "Attach ROS2 C++ process" },
      { "<leader>dre", mode = "n", desc = "Inspect ROS2 debug environment" },
    },
    config = function()
      local dap = require("dap")
      local dapui = require("dapui")
      local debug_ui = require("config.debug_ui")
      local ros2_debug = require("config.ros2_debug")
      local stm32_debug = require("config.stm32_debug")

      require("nvim-dap-virtual-text").setup({
        commented = true,
      })

      debug_ui.setup(dap)

      dapui.setup({
        floating = {
          border = "rounded",
        },
      })

      local cortex_debug_ok, cortex_debug = pcall(require, "dap-cortex-debug")
      if cortex_debug_ok then
        cortex_debug.setup({
          dapui_rtt = true,
          node_path = "node",
        })
      else
        vim.notify("nvim-dap-cortex-debug not available: " .. tostring(cortex_debug), vim.log.levels.WARN)
      end

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
      vim.keymap.set("n", "<leader>drb", function()
        require("lazy").load({ plugins = { "overseer.nvim" } })
        ros2_debug.build_current_package()
      end, { desc = "Build ROS2 package" })
      vim.keymap.set("n", "<leader>drr", function()
        require("lazy").load({ plugins = { "overseer.nvim" } })
        ros2_debug.run_node()
      end, { desc = "Run ROS2 node" })
      vim.keymap.set("n", "<leader>drp", ros2_debug.launch_python_node, { desc = "Debug ROS2 Python node" })
      vim.keymap.set("n", "<leader>drc", ros2_debug.launch_cpp_node, { desc = "Debug ROS2 C++ node" })
      vim.keymap.set("n", "<leader>dra", ros2_debug.attach_process, { desc = "Attach ROS2 C++ process" })
      vim.keymap.set("n", "<leader>dre", ros2_debug.inspect_environment, { desc = "Inspect ROS2 debug environment" })

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

      dap.configurations.c = vim.deepcopy(cpp_config)
      dap.configurations.cpp = vim.deepcopy(cpp_config)

      dap.configurations.python = dap.configurations.python or {}
      vim.list_extend(dap.configurations.python, ros2_debug.python_configurations())
      vim.list_extend(dap.configurations.c, ros2_debug.cpp_configurations())
      vim.list_extend(dap.configurations.cpp, ros2_debug.cpp_configurations())

      local stm32_configs = stm32_debug.cortex_configurations()
      if stm32_configs then
        vim.list_extend(dap.configurations.c, stm32_configs)
        vim.list_extend(dap.configurations.cpp, stm32_configs)
      end
    end,
  },
}
