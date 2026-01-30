return {
  {
    'aserowy/tmux.nvim',
    config = function()
      require('tmux').setup({
        navigation = {
          enable_default_keybindings = false,
        },
        resize = {
          -- enables default keybindings (A-hjkl) for normal mode
          enable_default_keybindings = false,
        }
      })
     
      local map = vim.keymap.set
      local opts = { noremap = true, silent = true }

      map("n", "<M-j>", function() require("tmux").move_left() end, opts)
      map("n", "<M-k>", function() require("tmux").move_bottom() end, opts)
      map("n", "<M-i>", function() require("tmux").move_top() end, opts)
      map("n", "<M-l>", function() require("tmux").move_right() end, opts)

      map("n", "<M-J>", function() require("tmux").resize_left() end, opts)
      map("n", "<M-K>", function() require("tmux").resize_bottom() end, opts)
      map("n", "<M-I>", function() require("tmux").resize_top() end, opts)
      map("n", "<M-L>", function() require("tmux").resize_right() end, opts)
    end
  }
}
