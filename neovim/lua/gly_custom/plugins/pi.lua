return {
  "carderne/pi-nvim",
  version = "v0.2.5",
  config = function()
    -- This repo owns the <leader>k* prefix; the plugin's default <leader>p
    -- would clobber visual-mode paste from gly_custom/remap.lua.
    require("pi-nvim").setup({ set_default_keymaps = false })

    vim.keymap.set("n", "<leader>kk", function()
      require("gly_custom.pi_terminal").toggle()
    end, { desc = "Toggle pi mirror split" })
    vim.keymap.set("n", "<leader>ka", function()
      require("gly_custom.pi_prompt").open({ default_context = "file" })
    end, { desc = "Ask pi about current file" })
    vim.keymap.set("x", "<leader>kh", function()
      require("gly_custom.pi_prompt").open({ default_context = "selection" })
    end, { desc = "Add range to pi" })
    vim.keymap.set("n", "<leader>kp", ":PiPing<CR>", { desc = "Ping pi" })
    vim.keymap.set("n", "<leader>ks", ":PiSessions<CR>", { desc = "List pi sessions" })
  end,
}
