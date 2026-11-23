return {
  name = "appdev",
  generator = function(opts)
    return require("appdev.integrations.overseer").templates(opts)
  end,
}
