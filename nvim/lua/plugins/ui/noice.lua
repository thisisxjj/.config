return {
	"folke/noice.nvim",
	event = "VeryLazy",
	dependencies = {
		"MunifTanjim/nui.nvim",
	},
	opts = {
		-- 核心避让：禁用 noice 的普通通知功能，完全交给 snacks
		notify = { enabled = false },

		lsp = {
			-- LSP 进度提示：如果你觉得右下角太吵，可以把这里改成 false
			progress = { enabled = true },
			override = {
				["vim.lsp.util.convert_input_to_markdown_lines"] = true,
				["vim.lsp.util.stylize_markdown"] = true,
				["cmp.entry.get_documentation"] = true,
			},
		},
		routes = {
			{
				filter = {
					event = "msg_show",
					any = {
						{ find = "%d+L, %d+B" },
						{ find = "; after #%d+" },
						{ find = "; before #%d+" },
					},
				},
				view = "mini",
			},
			{
				filter = {
					event = "msg_show",
					min_height = 20, -- 触发条件：只要输出的行数超过 20 行，就判定为长消息
				},
				view = "popup", -- 魔法在这里：让它以悬浮窗 (popup) 的形式展现
			},
		},
		presets = {
			bottom_search = false,
			command_palette = true,
			long_message_to_split = false,
		},
		views = {
			popup = {
				size = {
					width = "70%", -- 限制宽度：可以是具体的字符列数（比如 80 或 100），也可以是屏幕百分比（比如 "60%"）
					height = "auto",
				},
			},
			cmdline_popup = {
				position = {
					row = "40%",
					col = "50%",
				},
			},
			cmdline_popupmenu = {
				position = {
					row = "auto", -- 自动跟随 cmdline
					col = "auto",
				},
			},
		},
	},
	keys = {
		-- 1. 最核心的：一键呼出历史消息搜索 (原先的 <leader>snt)
		-- 改成 <leader>m (代表 Messages)，只有两个键，极其顺手
		{ "<leader>mm", "<cmd>Noice telescope<cr>", desc = "Messages History (Noice)" },
		-- 2. 清除屏幕上的所有残留通知和消息 (原先的 <leader>snd)
		{
			"<leader>md",
			function()
				require("noice").cmd("dismiss")
			end,
			desc = "Dismiss Messages",
		},

		-- 3. 查看上一条一闪而过的消息
		{
			"<leader>ml",
			function()
				require("noice").cmd("last")
			end,
			desc = "Last Message",
		},

		-- 4. 保持 LSP 悬浮窗滚动不变 (因为 Ctrl 组合键在输入模式下是最合理的)
		{
			"<c-f>",
			function()
				if not require("noice.lsp").scroll(4) then
					return "<c-f>"
				end
			end,
			silent = true,
			expr = true,
			desc = "Scroll Forward",
			mode = { "i", "n", "s" },
		},
		{
			"<c-b>",
			function()
				if not require("noice.lsp").scroll(-4) then
					return "<c-b>"
				end
			end,
			silent = true,
			expr = true,
			desc = "Scroll Backward",
			mode = { "i", "n", "s" },
		},
		{
			"<S-Enter>",
			function()
				require("noice").redirect(vim.fn.getcmdline())
			end,
			mode = "c",
			desc = "Redirect Cmdline",
		},
	},
	config = function(_, opts)
		if vim.o.filetype == "lazy" then
			vim.cmd([[messages clear]])
		end
		require("noice").setup(opts)
	end,
}
