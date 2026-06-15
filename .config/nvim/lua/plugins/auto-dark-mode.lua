-- Follow the system light/dark mode (driven by darkman) and switch the
-- catppuccin flavour live in every running instance: latte / mocha.
return {
  "f-person/auto-dark-mode.nvim",
  opts = {
    set_dark_mode = function()
      vim.o.background = "dark"
      vim.cmd.colorscheme("catppuccin-mocha")
    end,
    set_light_mode = function()
      vim.o.background = "light"
      vim.cmd.colorscheme("catppuccin-latte")
    end,
  },
}
