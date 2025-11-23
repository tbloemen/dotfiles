return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        pyright = {},
        ruff = {},
        marksman = {
          -- Enable marksman for markdown files
          filetypes = { "markdown", "markdown.mdx" },
          root_dir = function(fname)
            local util = require("lspconfig.util")
            return util.root_pattern(".obsidian", ".git")(fname)
          end,
        },
      },
      diagnostics = {
        virtual_text = false,
      },
    },
  },
}
