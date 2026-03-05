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
    local ai_dir = startup_dir .. "/.ai"
    local opencode_config = ai_dir .. "/opencode.json"

    local opencode_cmd
    if vim.fn.isdirectory(ai_dir) == 1 and vim.fn.filereadable(opencode_config) == 1
    then
      opencode_cmd = string.format(
        "OPENCODE_CONFIG=%s opencode %s --agent plan --port",
        vim.fn.shellescape(opencode_config),
        vim.fn.shellescape(startup_dir)
      )
    else
      opencode_cmd = string.format(
        "opencode %s --agent plan --port",
        vim.fn.shellescape(startup_dir)
      )
    end

    ---@type opencode.Opts
    vim.g.opencode_opts = {
      -- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition" on the type or field.
      provider = {
        enabled = "terminal",
        cmd = opencode_cmd,
      },
    }

    -- Required for `opts.events.reload`.
    vim.o.autoread = true

    -- Recommended/example keymaps.
    vim.keymap.set({ "n", "x" }, "<leader>kx", function()
      require("opencode").select()
    end, { desc = "Execute opencode action…" })
    vim.keymap.set({ "n", "t" }, "<leader>kk", function()
      require("opencode").toggle()
      vim.cmd("wincmd =")
    end, { desc = "Toggle opencode" })

    vim.keymap.set("x", "<leader>kh", function()
      return require("opencode").operator("@this ")
    end, { desc = "Add range to opencode", expr = true })
    vim.keymap.set("n", "<leader>ka", function()
      require("opencode").prompt("@buffer ")
    end, { desc = "Ask opencode about current file" })

    vim.keymap.set({ "n", "t", "x" }, "<C-u>", function()
      require("opencode").command("session.half.page.up")
    end, { desc = "Scroll opencode up" })
    vim.keymap.set({ "n", "t", "x" }, "<C-d>", function()
      require("opencode").command("session.half.page.down")
    end, { desc = "Scroll opencode down" })
  end,
}
