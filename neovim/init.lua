require("gly_custom.config.lazy")
require("gly_custom.remap")
require("gly_custom.set")

-- For opencode exit terminal
vim.keymap.set("t", "<C-w>", [[<C-\><C-n>]], { desc = "Terminal to normal mode" })
