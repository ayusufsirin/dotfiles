return {
  {
    name = "appdev.nvim",
    dir = vim.fn.stdpath("config"),
    lazy = false,
    config = function()
      require("appdev").setup({
        adapters = {
          stm32 = {
            cubeclt = {
              install_dir = "/home/joseph/Applications/STMicroelectronics/STM32CubeCLT/stm32cubeclt_1.21.0",
            },
            cubeide_container = {
              enabled = true,
              image = "xanderhendriks/stm32cubeide:16.0",
            },
          },
        },
        project_config = {
          trusted_lua = true,
        },
      })
    end,
  },
}
