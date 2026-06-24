return {
  "nickjvandyke/opencode.nvim",
  version = "v0.13.2", -- Latest stable release
  dependencies = {
    {
      "folke/snacks.nvim",
      opts = { input = {}, picker = {}, terminal = {} },
    },
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

    local snacks_terminal_opts = {
      win = {
        position = "right",
        enter = false,
      },
    }

    ---@type opencode.Opts
    vim.g.opencode_opts = {
      server = {
        start = function()
          require("snacks.terminal").open(opencode_cmd, snacks_terminal_opts)
        end,
      },
    }

    -- Required for `opts.events.reload`.
    vim.o.autoread = true

    -- Recommended/example keymaps.
    vim.keymap.set({ "n", "x" }, "<leader>kx", function()
      require("opencode").select()
    end, { desc = "Execute opencode action…" })
    vim.keymap.set({ "n", "t" }, "<leader>kk", function()
      require("snacks.terminal").toggle(opencode_cmd, snacks_terminal_opts)
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
