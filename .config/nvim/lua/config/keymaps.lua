-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
Snacks.toggle({
  name = "Virtual Lines",
  get = function()
    return vim.diagnostic.config().virtual_lines ~= false
  end,
  set = function(state)
    vim.diagnostic.config({ virtual_lines = state, virtual_text = not state })
  end,
}):map("<leader>uk")
