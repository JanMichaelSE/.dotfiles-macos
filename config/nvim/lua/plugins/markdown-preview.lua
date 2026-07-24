return {
  -- Markdown Previews
  "iamcco/markdown-preview.nvim",
  cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
  -- Keep npm from generating an untracked lockfile in Lazy's plugin checkout.
  build = "cd app && npm install --no-package-lock",
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
