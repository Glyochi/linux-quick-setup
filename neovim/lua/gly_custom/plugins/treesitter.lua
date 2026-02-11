return {
	{
		"nvim-treesitter/nvim-treesitter",
		lazy = false,
		build = ":TSUpdate",
		config = function()
			local ok, configs = pcall(require, "nvim-treesitter.configs")
			if not ok then
				return
			end

			configs.setup({
				ensure_installed = {
					"lua",
					"vim",
					"vimdoc",
					"query",
					"python",
					"javascript",
					"typescript",
					"html",
					"c",
				},
				highlight = { enable = true },
				indent = { enable = true },
				auto_install = false,
			})
		end,
	},
}
