return {
  {
    "catppuccin/nvim",
    opts = {
      transparent_background = true,
      styles = {
        sidebars = "transparent",
        floats = "transparent",
      },
    },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      -- Neovim 0.12 ships an opaque colorscheme named `catppuccin`.
      -- Use the plugin-specific name so the options above take effect.
      colorscheme = "catppuccin-mocha",
    },
  },
}
