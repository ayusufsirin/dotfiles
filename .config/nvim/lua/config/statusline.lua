local M = {}

local diagnostics = require("config.diagnostics")

function M.diagnostic_component(level)
  return {
    function()
      if diagnostics.any_open() then
        return ""
      end

      local count = diagnostics.count(level)
      if count == 0 then
        return ""
      end

      return string.format("%s %d", diagnostics.icon(level), count)
    end,
    color = level == "error" and { fg = "#fb4934" }
      or level == "warn" and { fg = "#fabd2f" }
      or level == "info" and { fg = "#83a598" }
      or { fg = "#b8bb26" },
    on_click = function()
      diagnostics.toggle(level)
    end,
  }
end

function M.filename()
  return {
    "filename",
    path = 1,
    symbols = {
      modified = " [+]",
      readonly = " [ro]",
      unnamed = "[No Name]",
      newfile = " [new]",
    },
  }
end

return M
