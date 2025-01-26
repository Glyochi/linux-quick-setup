
function TransparentBackground()
	vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
	vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
end

vim.api.nvim_create_autocmd("ColorScheme", {
	pattern = "*",
	callback = function()
		TransparentBackground()
	end
})

return {
		{
			"EdenEast/nightfox.nvim",
			lazy = true,
			priority= 1000,
		},
		{
			"folke/tokyonight.nvim",
			lazy = false,
			priority= 1000,
			config = function()
				vim.cmd('colorscheme tokyonight')
				TransparentBackground()
			end
		},
}

