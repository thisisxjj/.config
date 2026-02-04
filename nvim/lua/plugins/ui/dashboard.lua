return {
  {
    "nvimdev/dashboard-nvim",
    event = "VimEnter",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = function()
      local header = {
        "",
        "  _   _                 _           ",
        " | \\ | | ___  _   _  __| | ___ _ __ ",
        " |  \\| |/ _ \\| | | |/ _` |/ _ \\ '__|",
        " | |\\  | (_) | |_| | (_| |  __/ |   ",
        " |_| \\_|\\___/ \\__,_|\\__,_|\\___|_|   ",
        "",
      }

      return {
        theme = "doom",
        config = {
          header = header,
          center = {
            { icon = " ", desc = "New file", key = "n", action = "enew" },
            { icon = " ", desc = "Open tree", key = "e", action = "NvimTreeToggle" },
            { icon = " ", desc = "Edit config", key = "c", action = "edit $MYVIMRC" },
            { icon = "󰒲 ", desc = "Lazy", key = "l", action = "Lazy" },
            { icon = "󰗼 ", desc = "Quit", key = "q", action = "qa" },
          },
          footer = {},
        },
      }
    end,
    config = function(_, opts)
      require("dashboard").setup(opts)

      local function open_when_dir()
        if vim.bo.filetype == "dashboard" then
          return
        end

        if vim.fn.argc() ~= 1 then
          return
        end

        local arg = vim.fn.argv(0)
        if vim.fn.isdirectory(arg) ~= 1 then
          return
        end

        vim.schedule(function()
          if vim.bo.filetype ~= "dashboard" then
            vim.cmd("Dashboard")
          end
        end)
      end

      open_when_dir()
    end,
  },
}
