return {
  {
    "nvim-tree/nvim-tree.lua",
    version = "*",
    lazy = false,
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<cr>", desc = "Open Explorer" },
    },
    opts = {
      reload_on_bufenter = true,
      hijack_cursor = true,
      hijack_netrw = true,
      sync_root_with_cwd = true,
      hijack_unnamed_buffer_when_opening = true,
      auto_reload_on_write = true,
      diagnostics = {
        enable = false,
      },
      hijack_directories = {
        enable = true,
        auto_open = true,
      },
      actions = {
        open_file = {
          quit_on_open = false,
          resize_window = true,
        },
      },
      update_focused_file = {
        enable = true,
      },
      view = {
        centralize_selection = true,
        adaptive_size = false,
        side = "right",
        preserve_window_proportions = true,
        width = 40,
      },
      renderer = {
        full_name = false,
        indent_markers = {
          enable = false,
        },
        root_folder_label = ":t",
        highlight_git = true,
      },
      filters = {
        dotfiles = false,
        git_ignored = false,
        git_clean = false,
        no_buffer = false,
      },
      git = {
        enable = true,
        ignore = false,
        timeout = 400,
      },
    },
    config = function(_, opts)
      local nvimtree = require("nvim-tree")
      local utils = require("nvim-tree.utils")

      local wrapped_input

      local function wrap_nvim_tree_input()
        if vim.ui.input == wrapped_input then
          return
        end

        local path_sep = utils.path_separator

        local function is_absolute(path)
          if not path or path == "" then
            return false
          end
          if utils.is_windows and path:match("^%a:[/\\]") then
            return true
          end
          return path:sub(1, 1) == path_sep
        end

        local original = vim.ui.input
        local function wrapped(input_opts, on_confirm)
          if type(input_opts) == "table" and vim.bo.filetype == "NvimTree" then
            if input_opts.prompt == "Create file " then
              local prefix = input_opts.default or ""
              if prefix ~= "" then
                prefix = utils.path_add_trailing(prefix)
              end
              local opts_trim = vim.tbl_extend("force", input_opts, { default = "" })
              return original(opts_trim, function(value)
                if value and value ~= "" and not is_absolute(value) then
                  value = prefix .. value
                end
                on_confirm(value)
              end)
            end

            if input_opts.prompt == "Rename to " then
              local default = input_opts.default or ""
              local prefix = ""
              local display_default = default
              local has_sep = default:find(path_sep, 1, true) ~= nil
              local has_drive = utils.is_windows and default:match("^%a:[/\\]") ~= nil

              if (has_sep or has_drive) and default ~= "" then
                local parent = vim.fn.fnamemodify(default, ":h")
                if parent ~= "" and parent ~= "." then
                  prefix = utils.path_add_trailing(parent)
                end
                display_default = vim.fn.fnamemodify(default, ":t")
              end

              local opts_trim = input_opts
              if display_default ~= default then
                opts_trim = vim.tbl_extend("force", input_opts, { default = display_default })
              end

              return original(opts_trim, function(value)
                if value and value ~= "" and prefix ~= "" and not is_absolute(value) then
                  value = prefix .. value
                end
                on_confirm(value)
              end)
            end
          end

          return original(input_opts, on_confirm)
        end

        wrapped_input = wrapped
        vim.ui.input = wrapped_input
      end

      local function keybindings(bufnr)
        wrap_nvim_tree_input()
        local api = require("nvim-tree.api")

        local function ops(desc)
          return {
            desc = "nvim-tree: " .. desc,
            buffer = bufnr,
            noremap = true,
            silent = true,
            nowait = true,
          }
        end

        -- default mappings
        api.config.mappings.default_on_attach(bufnr)

        -- jkli direction remap (raw key behavior, not API navigation)
        vim.keymap.set("n", "j", api.node.navigate.parent, ops("Parent"))
        vim.keymap.set("n", "k", "j", ops("Down"))
        vim.keymap.set("n", "i", "k", ops("Up"))
        vim.keymap.set("n", "l", api.node.open.edit, ops("Open/Expand"))

        -- disable h to avoid conflicts with global search remap
        vim.keymap.set("n", "h", "<Nop>", ops("Disable h"))

        -- custom mappings
        vim.keymap.set("n", "P", api.node.open.preview, ops("Preview"))
        vim.keymap.set("n", "v", api.node.open.vertical_no_picker, ops("Open Vertical"))
        vim.keymap.set("n", "h", api.node.open.horizontal_no_picker, ops("Open Horizontal"))
      end

      opts.on_attach = keybindings

      nvimtree.setup(opts)

      local function open_tree_on_setup(args)
        vim.schedule(function()
          local file = args.file
          local buf_name = vim.api.nvim_buf_get_name(0)
          local is_no_name_buffer = buf_name == ""
            and vim.bo.filetype == ""
            and vim.bo.buftype == ""
          local is_directory = vim.fn.isdirectory(file) == 1

          if not is_no_name_buffer and not is_directory then
            return
          end

          if is_directory then
            vim.cmd.cd(file)
          end

          require("nvim-tree.api").tree.open()
        end)
      end

      vim.api.nvim_create_autocmd("VimEnter", {
        group = vim.api.nvim_create_augroup("nvim-tree", { clear = true }),
        callback = open_tree_on_setup,
      })
    end,
  },
  {
    "antosha417/nvim-lsp-file-operations",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = true,
  },
}
