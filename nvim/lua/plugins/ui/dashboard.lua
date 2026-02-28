return {
	{
		"nvimdev/dashboard-nvim",
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = function()
			local header = {
				"                                                     ",
				"                                                     ",
				"                                                     ",
				"                                                     ",
				"                                                     ",
				"                                                     ",
				"                                                     ",
				"                                                     ",
				"  ███╗   ██╗███████╗ ██████╗ ██╗   ██╗██╗███╗   ███╗ ",
				"  ████╗  ██║██╔════╝██╔═══██╗██║   ██║██║████╗ ████║ ",
				"  ██╔██╗ ██║█████╗  ██║   ██║██║   ██║██║██╔████╔██║ ",
				"  ██║╚██╗██║██╔══╝  ██║   ██║╚██╗ ██╔╝██║██║╚██╔╝██║ ",
				"  ██║ ╚████║███████╗╚██████╔╝ ╚████╔╝ ██║██║ ╚═╝ ██║ ",
				"  ╚═╝  ╚═══╝╚══════╝ ╚═════╝   ╚═══╝  ╚═╝╚═╝     ╚═╝ ",
				"                                                     ",
			}

			return {
				theme = "doom",
				config = {
					header = header,
					center = {
						{ icon = " ", desc = "> New File", key = "n", action = "enew" },
						{ icon = " ", desc = "> Open Tree", key = "e", action = "NvimTreeToggle" },
						{ icon = "󰱼 ", desc = "> Find File", key = "f", action = "Telescope find_files" },
						{ icon = " ", desc = "> Find Word", key = "g", action = "Telescope live_grep" },
						{ icon = "󰒲 ", desc = "> Lazy Setup", key = "l", action = "Lazy" },
						{ icon = "󰗼 ", desc = "> Quit Nvim", key = "q", action = "qa" },
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
