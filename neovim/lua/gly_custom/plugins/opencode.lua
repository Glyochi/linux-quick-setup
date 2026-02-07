return {
  "NickvanDyke/opencode.nvim",
  dependencies = {
    -- Recommended for `ask()` and `select()`.
    -- Required for `snacks` provider.
    ---@module 'snacks' <- Loads `snacks.nvim` types for configuration intellisense.
    { "folke/snacks.nvim", opts = { input = {}, picker = {}, terminal = {} } },
  },
  config = function()
    local startup_dir = vim.fn.getcwd() -- Store nvim startup directory

    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition" on the type or field.
      provider = {
        enabled = "terminal",
        cmd = string.format('opencode "%s" --agent plan --port', startup_dir),
      },
    }

    -- Required for `opts.events.reload`.
    vim.o.autoread = true

    -- Recommended/example keymaps.
    vim.keymap.set({ "n", "x" }, "<leader>ka", function() require("opencode").ask("@this: ", { submit = true }) end,
      { desc = "Ask opencode…" })
    vim.keymap.set({ "n", "x" }, "<leader>kx", function() require("opencode").select() end,
      { desc = "Execute opencode action…" })
    vim.keymap.set({ "n", "t" }, "<leader>kk", function() require("opencode").toggle() end, { desc = "Toggle opencode" })
    vim.keymap.set({ "n", "x" }, "<leader>kd", function() require("opencode").command("session.interrupt") end,
      { desc = "Interupt opencode request" })

    vim.keymap.set("x", "<leader>kh", function()
      return require("opencode").operator("@this ")
    end, { desc = "Add range to opencode", expr = true })
    vim.keymap.set("x", "<leader>kh", function()
      return require("opencode").operator("@this ") .. "_"
    end, { desc = "Add line to opencode", expr = true })

    vim.keymap.set({"n", "t", "x"}, "<C-u>", function() require("opencode").command("session.half.page.up") end,
      { desc = "Scroll opencode up" })
    vim.keymap.set({"n", "t", "x"}, "<C-d>", function() require("opencode").command("session.half.page.down") end,
      { desc = "Scroll opencode down" })

  end,
}
