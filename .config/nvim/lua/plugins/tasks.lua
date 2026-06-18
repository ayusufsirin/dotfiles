return {
  {
    "stevearc/overseer.nvim",
    cmd = {
      "OverseerBuild",
      "OverseerClearCache",
      "OverseerClose",
      "OverseerDeleteBundle",
      "OverseerInfo",
      "OverseerLoadBundle",
      "OverseerOpen",
      "OverseerQuickAction",
      "OverseerRun",
      "OverseerRunCmd",
      "OverseerSaveBundle",
      "OverseerTaskAction",
      "OverseerToggle",
    },
    keys = {
      { "<leader>oo", "<cmd>OverseerToggle<CR>", desc = "Toggle task list" },
      { "<leader>or", "<cmd>OverseerRun<CR>", desc = "Run task" },
      { "<leader>oa", "<cmd>OverseerTaskAction<CR>", desc = "Task action" },
    },
    config = function()
      require("overseer").setup({
        templates = {
          "builtin",
          "ros2",
        },
        task_list = {
          direction = "bottom",
          min_height = 12,
          max_height = 18,
          bindings = {
            ["q"] = "Close",
            ["<CR>"] = "RunAction",
            ["o"] = "Open",
          },
        },
      })
    end,
  },
}
