return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {},
        ruff = {},
      },
      diagnostics = {
        virtual_text = false,
      },
    },
  },
}
