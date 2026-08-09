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
      -- formatting off entirely and shell out to the real `bean-format`
      -- binary on save instead, so the two never disagree.
      instant_alignment = false,
      auto_format_on_save = false,
    },
    config = function(_, opts)
      require("beancount").setup(opts)

      local group = vim.api.nvim_create_augroup("bean_format_on_save", { clear = true })
      vim.api.nvim_create_autocmd("BufWritePre", {
        group = group,
        callback = function(args)
          if vim.bo[args.buf].filetype ~= "beancount" then
            return
          end
          if vim.fn.executable("bean-format") == 0 then
            return
          end

          local lines = vim.api.nvim_buf_get_lines(args.buf, 0, -1, false)
          local input = table.concat(lines, "\n") .. "\n"

          local result = vim.system({ "bean-format", "-" }, { stdin = input, text = true }):wait()
          if result.code ~= 0 then
            vim.notify("bean-format failed:\n" .. (result.stderr or ""), vim.log.levels.ERROR)
            return
          end

          local formatted = vim.split(result.stdout, "\n", { plain = true })
          if formatted[#formatted] == "" then
            table.remove(formatted) -- drop the artefact of the trailing newline
          end

          if not vim.deep_equal(lines, formatted) then
            vim.api.nvim_buf_set_lines(args.buf, 0, -1, false, formatted)
          end
        end,
      })
    end,
  },
}
