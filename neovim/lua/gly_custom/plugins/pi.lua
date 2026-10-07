return {
  "carderne/pi-nvim",
  version = "v0.2.5",
  config = function()
    -- This repo owns the <leader>k* prefix; the plugin's default <leader>p
    -- would clobber visual-mode paste from gly_custom/remap.lua.
    require("pi-nvim").setup({ set_default_keymaps = false })

    vim.keymap.set("n", "<leader>kk", ":PiSend<CR>", { desc = "Ask pi" })
    vim.keymap.set("n", "<leader>ka", ":PiSendBuffer<CR>", { desc = "Ask pi about current buffer" })
    vim.keymap.set("x", "<leader>kh", ":PiSendSelection<CR>", { desc = "Add range to pi" })
    vim.keymap.set({ "n", "x" }, "<leader>kx", ":Pi<CR>", { desc = "Send to pi…" })
    vim.keymap.set("n", "<leader>kp", ":PiPing<CR>", { desc = "Ping pi" })
    vim.keymap.set("n", "<leader>ks", ":PiSessions<CR>", { desc = "List pi sessions" })
  end,
}
