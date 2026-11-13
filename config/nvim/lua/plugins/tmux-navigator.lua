-- Inside Rex (and not tmux), Ctrl-h/j/k/l moves between Neovim windows and,
-- at the edge, on to the neighbouring Rex pane, like vim-tmux-navigator.
local function rex_navigate(wincmd, direction)
  return function()
    local win = vim.api.nvim_get_current_win()
    vim.cmd.wincmd(wincmd)
    if vim.api.nvim_get_current_win() == win then
      vim.system({ "rex", "focus", "-s", vim.env.REX_SESSION, direction })
    end
  end
end

local in_rex = vim.env.REX_SESSION ~= nil and vim.env.TMUX == nil

return {
  "christoomey/vim-tmux-navigator",
  init = function()
    -- Otherwise the plugin maps its own Ctrl-h/j/k/l on load, over the Rex ones.
    if in_rex then vim.g.tmux_navigator_no_mappings = 1 end
  end,
  keys = function()
    if in_rex then
      return {
        { "<C-h>", rex_navigate("h", "left"), desc = "Rex Navigate Left" },
        { "<C-j>", rex_navigate("j", "down"), desc = "Rex Navigate Down" },
        { "<C-k>", rex_navigate("k", "up"), desc = "Rex Navigate Up" },
        { "<C-l>", rex_navigate("l", "right"), desc = "Rex Navigate Right" },
      }
    end
    return {
      { "<C-h>", "<cmd>TmuxNavigateLeft<cr>", desc = "Tmux Navigate Left" },
      { "<C-j>", "<cmd>TmuxNavigateDown<cr>", desc = "Tmux Navigate Down" },
      { "<C-k>", "<cmd>TmuxNavigateUp<cr>", desc = "Tmux Navigate Up" },
      { "<C-l>", "<cmd>TmuxNavigateRight<cr>", desc = "Tmux Navigate Right" },
    }
  end,
}
