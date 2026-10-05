local M = {
	"kevinhwang91/nvim-ufo",
	dependencies = { "kevinhwang91/promise-async" },
	opts = {
		filetype_exclude = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy", "mason" },
	},
	config = function(_, opts)
		vim.o.foldcolumn = "1" -- '0' is not bad
		vim.o.foldlevel = 99 -- Using ufo provider requires a large value
		vim.o.foldlevelstart = 99
		vim.o.foldenable = true

		require("ufo").setup({
			provider_selector = function(bufnr, filetype, buftype)
				return { "treesitter", "indent" }
			end,
		})
		-- Single fold actions
		vim.keymap.set("n", "<leader>dj", "zc", { remap = true, desc = "Fold close" })
		vim.keymap.set("n", "<leader>dJ", "zC", { remap = true, desc = "Fold close recursive" })
		vim.keymap.set("n", "<leader>dk", "zo", { remap = true, desc = "Fold open" })
		vim.keymap.set("n", "<leader>dK", "zO", { remap = true, desc = "Fold open recursive" })

		-- All folds (ufo)
		vim.keymap.set("n", "<leader>dD", require("ufo").closeAllFolds, { desc = "Fold close all" })
		vim.keymap.set("n", "<leader>dF", require("ufo").openAllFolds, { desc = "Fold open all" })
	end,
}

return M
