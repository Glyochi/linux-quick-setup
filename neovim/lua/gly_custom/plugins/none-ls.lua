return {
  {
    'nvimtools/none-ls.nvim',
	config = function()
        local null_ls = require("null-ls")

        null_ls.setup({
          sources = {
            null_ls.builtins.formatting.black,  -- reads pyproject.toml
          },
        })

        -- Keymap for your "FF"
        vim.keymap.set("n", "FF", function()
          vim.lsp.buf.format({
            async = true,
            filter = function(client)
              return client.name == "null-ls" or client.name == "none-ls"
            end,
          })
        end)

        -- (optional) format on save for Python
        vim.api.nvim_create_autocmd("BufWritePre", {
          pattern = "*.py",
          callback = function(args)
            vim.lsp.buf.format({
              bufnr = args.buf,
              filter = function(client)
                return client.name == "null-ls" or client.name == "none-ls"
              end,
            })
          end,
        })
    end
  }
}
