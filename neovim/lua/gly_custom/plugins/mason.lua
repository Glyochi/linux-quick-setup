return {
	{'williamboman/mason.nvim'},
	{'williamboman/mason-lspconfig.nvim'},
	{
		"williamboman/mason.nvim",
		config = function()
			require("mason").setup()
			require('mason-lspconfig').setup({
				-- Setting automatic new language server mapping from mason to lsp
				handlers = {
					function(server_name)
						require('lspconfig')[server_name].setup({})
					end,
				},
			})
		end
	}
}
