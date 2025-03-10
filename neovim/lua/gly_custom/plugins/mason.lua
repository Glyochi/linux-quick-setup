return {
	{'williamboman/mason-lspconfig.nvim'},
	{
        "williamboman/mason.nvim",
		config = function()
			require("mason").setup()
			require('mason-lspconfig').setup({
				-- Setting automatic new language server mapping from mason to lsp
				handlers = {
					function(server_name)

                        if server_name == 'volar' then
                            require('lspconfig')[server_name].setup({
                                init_options = {
                                  vue = {
                                    hybridMode = false,
                                  },
                                },
                                settings = {
                                  typescript = {
                                    inlayHints = {
                                      enumMemberValues = {
                                        enabled = true,
                                      },
                                      functionLikeReturnTypes = {
                                        enabled = true,
                                      },
                                      propertyDeclarationTypes = {
                                        enabled = true,
                                      },
                                      parameterTypes = {
                                        enabled = true,
                                        suppressWhenArgumentMatchesName = true,
                                      },
                                      variableTypes = {
                                        enabled = true,
                                      },
                                    },
                                  },
                                },
                            })
                            
                        elseif server_name == 'ts_ls' then
                            require('lspconfig')[server_name].setup({
                                filetypes = { 'typescript', 'javascript', 'javascriptreact', 'typescriptreact', 'vue' },
                                init_options = {
                                  plugins = {
                                    {
                                      name = '@vue/typescript-plugin',
                                      location = vim.fn.stdpath 'data' .. '/mason/packages/vue-language-server/node_modules/@vue/language-server',
                                      languages = { 'vue' },
                                    },
                                  },
                                },
                                settings = {
                                  typescript = {
                                    tsserver = {
                                      useSyntaxServer = false,
                                    },
                                    inlayHints = {
                                      includeInlayParameterNameHints = 'all',
                                      includeInlayParameterNameHintsWhenArgumentMatchesName = true,
                                      includeInlayFunctionParameterTypeHints = true,
                                      includeInlayVariableTypeHints = true,
                                      includeInlayVariableTypeHintsWhenTypeMatchesName = true,
                                      includeInlayPropertyDeclarationTypeHints = true,
                                      includeInlayFunctionLikeReturnTypeHints = true,
                                      includeInlayEnumMemberValueHints = true,
                                    },
                                  },
                                },
                            })
                        else
                            require('lspconfig')[server_name].setup({})
                        end
					end,
				},
			})
		end
	}
}
