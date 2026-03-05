return {
	"mfussenegger/nvim-lint",
	-- 确保在打开文件时就加载这个插件，而不是等到按快捷键
	event = { "BufReadPre", "BufNewFile" },
	opts = {
		-- 这里作为一个空的“桩位”，接收来自各个语言模块（比如 docker.lua）的注入
		linters_by_ft = {},
	},
	config = function(_, opts)
		local lint = require("lint")

		-- 1. 将收集到的所有 linters_by_ft 赋值给插件本体
		lint.linters_by_ft = opts.linters_by_ft

		-- 2. 🌟 核心引擎：创建自动命令，在特定时机触发代码检查
		local lint_augroup = vim.api.nvim_create_augroup("kickstart-nvim-lint", { clear = true })

		vim.api.nvim_create_autocmd({
			"BufEnter", -- 刚进入文件时检查一次
			"BufWritePost", -- 每次保存完文件后检查一次
			"InsertLeave", -- 退出插入模式（写完一段代码按 Esc）时检查一次
		}, {
			group = lint_augroup,
			callback = function()
				-- try_lint() 会自动读取当前文件的 filetype (如 dockerfile)
				-- 然后去 linters_by_ft 里找对应的 linter (如 hadolint) 并在后台静默执行
				lint.try_lint()
			end,
		})

		-- 3. (可选) 给自己留一个手动触发/调试的快捷键
		vim.keymap.set("n", "<leader>ll", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}
