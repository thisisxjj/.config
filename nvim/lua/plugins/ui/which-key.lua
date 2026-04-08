return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		opts_extend = { "spec" },
		opts = {
			preset = "helix",
			delay = 0,
			icons = {
				mappings = true,
			},
			spec = {
				{
					mode = { "n", "x" },
					{ "<leader>b", group = "缓冲区" },
					{ "<leader>c", group = "代码" },
					{ "<leader>d", group = "调试" },
					{ "<leader>f", group = "查找" },
					{ "<leader>g", group = "Git" },
					{ "<leader>gb", group = "Git 缓冲/Blame" },
					{ "<leader>gd", group = "Git Diff/Deleted" },
					{ "<leader>gh", group = "Git Hunks" },
					{ "<leader>m", group = "消息" },
					{ "<leader>n", group = "通知/插入" },
					{ "<leader>q", group = "退出" },
					{ "<leader>s", group = "搜索" },
					{ "<leader>t", group = "开关/标签页" },
					{ "<leader>w", group = "写入/窗口" },
					{ "[", group = "上一个" },
					{ "]", group = "下一个" },
					{ "g", group = "跳转" },
					{ "z", group = "折叠" },
					{ "gx", desc = "系统应用打开" },
				},
				{
					mode = "n",
					{ "j", desc = "左移（原 h）" },
					{ "k", desc = "下移（原 j）" },
					{ "i", desc = "上移（原 k）" },
					{ "l", desc = "右移（原 l）" },
					{ "J", desc = "到行首（0，含缩进）" },
					{ "K", desc = "向下 5 行（5j）" },
					{ "I", desc = "向上 5 行（5k）" },
					{ "L", desc = "到行尾（$）" },
					{ "n", desc = "进入插入（原 i）" },
					{ "N", desc = "行首插入（原 I）" },
					{ "h", desc = "搜索下一个（原 n）" },
					{ "H", desc = "搜索上一个（原 N）" },
					{ "gm", desc = "选中下一个搜索匹配" },
					{ "gM", desc = "选中上一个搜索匹配" },
					{ "gh", desc = "LSP 缓冲区中会被 Hover 覆盖" },
				},
			},
		},
		keys = {
			{
				"<leader>?",
				function()
					require("which-key").show({ global = false })
				end,
				desc = "Buffer Keymaps (which-key)",
			},
			{
				"<c-w><space>",
				function()
					require("which-key").show({ keys = "<c-w>", loop = true })
				end,
				desc = "Window Hydra Mode (which-key)",
			},
		},
		config = function(_, opts)
			require("which-key").setup(opts)
		end,
	},
}
