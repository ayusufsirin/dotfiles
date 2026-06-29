local M = {}

M.defaults = {
  adapters = {
    ros2 = true,
    stm32 = {
      cubeclt = {
        install_dir = vim.env.STM32CUBECLT_DIR or vim.env.STM32CUBEIDE_DIR,
        workspace_dir = vim.fn.stdpath("cache") .. "/appdev-stm32-workspace",
      },
      cubeide_container = {
        enabled = false,
        image = "xanderhendriks/stm32cubeide:16.0",
        workspace_dir = "/tmp/appdev-stm32-workspace",
        project_mount_root = "/workspace",
        user = vim.loop.getuid and tostring(vim.loop.getuid()) .. ":" .. tostring(vim.loop.getgid()) or nil,
      },
    },
  },
  project_config = {
    trusted_lua = false,
    filenames = {
      ".nvim/appdev.lua",
      ".nvim/stm32.lua",
      ".stm32-nvim.lua",
    },
  },
  ui = {
    winbar = true,
  },
  overseer = {
    open_on_run = true,
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", vim.deepcopy(M.defaults), opts or {})
  return M.options
end

function M.get()
  return M.options
end

return M
