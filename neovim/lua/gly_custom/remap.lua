vim.keymap.set("n", "<leader>pv", vim.cmd.Ex)

-- move the whole highlighted block
vim.keymap.set("v", "J", ":m '>+1<CR>gv=gv")
vim.keymap.set("v", "K", ":m '<-2<CR>gv=gv")

-- paste without replacing the buffer
vim.keymap.set("x", "<leader>p", "\"_dP")



-- supposedly copy to clipboard (+ register) and can use outside of vim
-- vim.keymap.set("n", "<leader>y", "\"+y")
-- vim.keymap.set("v", "<leader>y", "\"+y")
-- vim.keymap.set("n", "<leader>Y", "\"+Y")



return {
}

