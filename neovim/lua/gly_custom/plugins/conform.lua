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
				lua = { "stylua" },
				markdown = { "prettier" },
				-- Add other file types as needed
			},
			formatters = {
				prettier = {
					prepend_args = function(_, ctx)
						if ctx.filename:match("%.md$") then
							return { "--prose-wrap", "always" }
						end
						return {}
					end,
				},
			},
			-- Optional: enable format on save
			format_on_save = { timeout_ms = 500, interval_ms = 500 },
		},
	},
}
