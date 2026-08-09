return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "beancount" } },
  },
  {
    "hxueh/beancount.nvim",
    ft = { "beancount", "bean" },
    dependencies = {
      {
        "saghen/blink.cmp",
        optional = true,
        opts = function(_, opts)
          table.insert(opts.sources.default, "beancount")
          opts.sources.providers = opts.sources.providers or {}
          opts.sources.providers.beancount = {
            name = "beancount",
            module = "beancount.completion.blink",
            score_offset = 100,
            opts = {
              trigger_characters = { ":", "#", "^", '"', " " },
            },
          }
          return opts
        end,
      },
      {
        "L3MON4D3/LuaSnip",
      },
    },
    opts = {
      -- beancount.nvim's own alignment doesn't match bean-format's column
      -- widths (bean-format derives them from the whole file). Turn its
      -- formatting off entirely and let conform.nvim's builtin `bean-format`
      -- formatter (wired up below) own format-on-save instead, so the two
      -- never disagree.
      instant_alignment = false,
      auto_format_on_save = false,

      -- bean-check only validates the file it's handed. Without this, the
      -- plugin defaults to checking whichever buffer you're editing (e.g.
      -- a monthly ledger), so every account looks "not opened" because it
      -- never sees main.beancount's `include`s. Pin it to the real entry
      -- point, matching `bean-check main.beancount`.
      main_bean_file = vim.fn.expand("~/Documents/finance/main.beancount"),
    },
  },
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        -- Ships as a builtin conform formatter; just runs `bean-format -`.
        beancount = { "bean-format" },
      },
    },
  },
}
