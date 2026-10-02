-- Inline diagnostics that wrap long messages to the window width instead of
-- overflowing (native virtual_text/virtual_lines never wrap).
return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "VeryLazy",
  priority = 1000,
  opts = {
    options = {
      overflow = { mode = "wrap" },
      multilines = { enabled = true },
    },
  },
}
