-- LSP keymaps
return {
  "neovim/nvim-lspconfig",
  opts = {
    servers = {
      ["*"] = {
        keys = {
          { "gd", vim.lsp.buf.definition, desc = "LSP: Go to definition" },
          { "gD", vim.lsp.buf.declaration, desc = "LSP: Go to declaration" },
          { "gi", vim.lsp.buf.implementation, desc = "LSP: Go to implementation" },
          { "<leader>rn", vim.lsp.buf.rename, desc = "LSP: Rename" },
          { "<leader>se", vim.diagnostic.open_float, desc = "[S]how [E]rror Diagnostic" },
          -- Disable LazyVim keymap as I now use "gi"
          { "gI", false },
        },
      },
    },
  },
}
