return {
  "neovim/nvim-lspconfig",
  opts = {
    -- Inline diagnostics are drawn by tiny-inline-diagnostic.nvim
    -- (plugins/tiny-inline-diagnostic.lua), which wraps long messages.
    diagnostics = {
      virtual_text = false,
    },
  },
}
