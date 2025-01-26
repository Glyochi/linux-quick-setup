return {
	{	
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function () 
			local configs = require("nvim-treesitter.configs")

			configs.setup({
				ensure_installed = { "vimdoc", "c", "lua", "vim", "vimdoc", "query", "elixir", "heex", "javascript", "typescript", "html", "python" },
				sync_install = false,
				highlight = { enable = true },
				indent = { enable = true },  
			})
		end

	},
}
