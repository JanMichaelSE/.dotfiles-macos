return {
  "nvim-telescope/telescope.nvim",
  keys = function()
    return {
      { "<leader>?", "<cmd>Telescope oldfiles<cr>", desc = "[?] Find recently opened files" },
      { "<leader><space>", "<cmd>Telescope buffers<cr>", desc = "[ ] Find existing buffers" },
      { "<leader>sf", "<cmd>Telescope find_files<cr>", desc = "[S]earch [F]iles" },
      { "<leader>sh", "<cmd>Telescope help_tags<cr>", desc = "[S]earch [H]elp" },
      { "<leader>sw", "<cmd>Telescope grep_string<cr>", desc = "[S]earch current [W]ord" },
      { "<leader>sg", "<cmd>Telescope live_grep<cr>", desc = "[S]earch by [G]rep" },
      { "<leader>sd", "<cmd>Telescope diagnostics<cr>", desc = "[S]earch [D]iagnostics" },
    }
  end,
}
