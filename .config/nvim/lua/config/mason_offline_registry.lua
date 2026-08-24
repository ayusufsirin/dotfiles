local offline = require("config.offline")

local cortex_debug_module = "config.mason_offline_registry.cortex_debug"

package.preload[cortex_debug_module] = function()
  return {
    name = "cortex-debug",
    description = "Debug adapter for Cortex-M microcontrollers.",
    homepage = "https://github.com/Marus/cortex-debug",
    licenses = { "MIT" },
    languages = { "C", "C++", "Rust" },
    categories = { "DAP" },
    source = {
      id = "pkg:generic/cortex-debug@1.12.1",
      download = {
        files = {
          ["marus25.cortex-debug-1.12.1.vsix"] = offline.cortex_debug_url(),
        },
      },
    },
    share = {
      ["cortex-debug/"] = "extension/",
    },
  }
end

return {
  cortex_debug = cortex_debug_module,
}
