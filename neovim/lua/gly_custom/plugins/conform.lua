return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        -- Add other file types as needed
      },
      -- Optional: enable format on save
      format_on_save = { timeout_ms = 500, interval_ms = 500 },
    },
  }
}
