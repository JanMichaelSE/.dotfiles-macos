return {
  -- Markdown Previews
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  -- Keep npm from generating an untracked lockfile in Lazy's plugin checkout.
  -- Pin to the versions in the plugin's yarn.lock: newer @chemzqm/neovim drops
  -- `msgpack-lite`, which the plugin still requires at startup.
  build = "cd app && npm install --no-package-lock --no-save @chemzqm/neovim@5.7.9 log4js@6.4.0 socket.io@2.4.0 tslib@1.9.3",
  init = function()
    vim.g.mkdp_filetypes = { "markdown" }
    vim.g.mkdp_theme = "dark"
  end,
  ft = { "markdown" },
  config = function()
    vim.keymap.set(
      "n",
      "<leader>mp",
      "<cmd>MarkdownPreview<CR>",
      { noremap = true, desc = "Preview Markdown in Browser" }
    )
    vim.keymap.set(
      "n",
      "<leader>ms",
      "<cmd>MarkdownPreviewStop<CR>",
      { noremap = true, desc = "Stop Preview Markdown" }
    )
  end,
}
