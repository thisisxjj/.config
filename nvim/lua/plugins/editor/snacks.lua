return {
	"folke/snacks.nvim",
	priority = 1000,
	lazy = false,
	opts = {
		-- 核心：关闭 Snacks 的 Picker，让你的 Telescope 独揽大权
		picker = { enabled = false },

		-- 开启通知系统，接管原本枯燥的 print 和 error
		notifier = { enabled = true },
		input = { enabled = false },

		-- 保留不冲突的体验增强功能（按需开启）
		indent = { enabled = true }, -- 缩进线
		words = { enabled = true }, -- 相同单词高亮
		scroll = { enabled = true }, -- 平滑滚动
	},
	keys = {
		-- 专门为通知系统分配独立快捷键，避开你的 <leader>s (Search/Telescope) 命名空间
		{
			"<leader>n",
			function()
				require("snacks").notifier.show_history()
			end,
			desc = "Notification History",
		},
		{
			"<leader>un",
			function()
				require("snacks").notifier.hide()
			end,
			desc = "Dismiss All Notifications",
		},
	},
}
