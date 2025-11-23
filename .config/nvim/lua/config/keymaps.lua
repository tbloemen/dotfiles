-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("", "<leader>uk", function()
  local new_value = not vim.diagnostic.config().virtual_lines
  vim.diagnostic.config({
    virtual_lines = new_value,
    virtual_text = not new_value,
  })
  print("lsp_lines " .. (new_value and "enabled" or "disabled"))
end, { desc = "Toggle lsp_lines" })
