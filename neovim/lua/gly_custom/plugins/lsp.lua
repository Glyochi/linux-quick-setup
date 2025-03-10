return {
	{'neovim/nvim-lspconfig'},
	{'hrsh7th/cmp-nvim-lsp'},
	{
		'hrsh7th/nvim-cmp', 
		config = function()
			-- Reserve a space in the gutter
			vim.opt.signcolumn = 'yes'

			-- Add cmp_nvim_lsp capabilities settings to lspconfig
			-- This should be executed before you configure any language server
			local lspconfig_defaults = require('lspconfig').util.default_config
			lspconfig_defaults.capabilities = vim.tbl_deep_extend(
			  'force',
			  lspconfig_defaults.capabilities,
			  require('cmp_nvim_lsp').default_capabilities()
			)

			-- This is where you enable features that only work
			-- if there is a language server active in the file
			vim.api.nvim_create_autocmd('LspAttach', {
			  desc = 'LSP actions',
			  callback = function(event)
			    local opts = {buffer = event.buf}

			    vim.keymap.set('n', 'K', '<cmd>lua vim.lsp.buf.hover()<cr>', opts)
			    vim.keymap.set('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<cr>', opts)
			    vim.keymap.set('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<cr>', opts)
			    vim.keymap.set('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<cr>', opts)
			    vim.keymap.set('n', 'go', '<cmd>lua vim.lsp.buf.type_definition()<cr>', opts)
			    vim.keymap.set('n', 'gr', '<cmd>lua vim.lsp.buf.references()<cr>', opts)
			    vim.keymap.set('n', 'gs', '<cmd>lua vim.lsp.buf.signature_help()<cr>', opts)
			    vim.keymap.set('n', '<leader>eh', '<cmd>lua vim.diagnostic.open_float()<cr>', opts)
			    vim.keymap.set('n', '<leader>en', '<cmd>lua vim.diagnostic.goto_next()<cr>', opts)
			    vim.keymap.set('n', '<leader>ep', '<cmd>lua vim.diagnostic.goto_prev()<cr>', opts)
			    vim.keymap.set('n', '<F2>', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
			    vim.keymap.set({'n', 'x'}, 'ff', '<cmd>lua vim.lsp.buf.format({async = true})<cr>', opts)
			    vim.keymap.set('n', '<F4>', '<cmd>lua vim.lsp.buf.code_action()<cr>', opts)
			  end,
			})

			-- These are just examples. Replace them with the language
			-- servers you have installed in your system
			-- Gly notes: with the addition of 'williamboman/mason' and 'williamboman/mason-lspconfig', we get LspInstall which will take care of setting up these language servers **I THINK**
			--
			-- require('lspconfig').vimls.setup({})
			-- require('lspconfig').gleam.setup({})
			-- require('lspconfig').rust_analyzer.setup({})
			-- require('lspconfig').lua_ls.setup({})
            require('lspconfig').pyright.setup({
                settings = {
                    python = {
                        analysis = {
                            extraPaths = {
                                '/home/gly/projects/tinygrad'
                            }
                        }
                    }
                }
            })

			local cmp = require('cmp')

			cmp.setup({
				sources = {
					{name = 'nvim_lsp'},
				},
				snippet = {
					expand = function(args)
						-- You need Neovim v0.10 to use vim.snippet
						vim.snippet.expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					['<C-p>'] = cmp.mapping.select_prev_item({behavior = 'select'}),
					['<C-n>'] = cmp.mapping.select_next_item({behavior = 'select'}),

					-- `Enter` key to confirm completion
					['<CR>'] = cmp.mapping.confirm({select = true}),

					-- Ctrl+Space to trigger completion menu
					['<C-Space>'] = cmp.mapping.complete(),
				}),
			})
		end
	},
}
