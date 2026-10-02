-- Soft-wrap long diagnostic messages in the Trouble list instead of
-- letting them run off the right edge.
return {
  "folke/trouble.nvim",
  opts = {
    win = { wo = { wrap = true } },
  },
}
