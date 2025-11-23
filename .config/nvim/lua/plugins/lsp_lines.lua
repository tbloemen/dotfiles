return {
  "https://git.sr.ht/~whynothugo/lsp_lines.nvim",
  event = "VeryLazy",
  config = function()
    require("lsp_lines").setup()

    -- Disable the default virtual_text diagnostics
    vim.diagnostic.config({
      virtual_text = false,
      virtual_lines = true, -- show lines by default
    })
  end,
}
