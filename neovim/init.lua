require("gly_custom.config.lazy")
require("gly_custom.remap")
require("gly_custom.set")

-- Escape a terminal buffer (for example one opened by the pi-nvim bridge) to normal mode
vim.keymap.set("t", "<C-w>", [[<C-\><C-n>]], { desc = "Terminal to normal mode" })
