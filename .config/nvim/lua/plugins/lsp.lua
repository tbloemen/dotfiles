return {
  "neovim/nvim-lspconfig",
  opts = {
    -- Diagnostics as virtual lines below the code instead of inline text
    -- (native since nvim 0.11). Toggle with <leader>uk (config/keymaps.lua).
    diagnostics = {
      virtual_text = false,
      virtual_lines = true,
    },
  },
}
