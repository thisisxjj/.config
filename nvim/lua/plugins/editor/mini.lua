return {
	{
		"nvim-mini/mini.nvim",
		config = function()
			local gen_spec = require("mini.ai").gen_spec
			-- ====================================================================
			-- 1. mini.ai 适配
			-- 核心思路：让 mini.ai 原生支持你的 'n' (inner) 逻辑
			-- ====================================================================
			require("mini.ai").setup({
				n_lines = 500,
				mappings = {
					-- 将默认的 'i' (inside) 改成你的 'n'
					-- 这样配置后，你的 dnw (删除单词)、cn" (修改引号) 会直接触发 mini.ai 的高级匹配
					inside = "n",
					around = "a",

					-- 下面这些是进阶指令，如果有冲突可以改，通常保持默认即可
					around_next = "ah",
					inside_next = "nh",
					around_last = "ap",
					inside_last = "np",
					goto_left = "g[",
					goto_right = "g]",
				},
				-- 🌟 替代 nvim-treesitter-textobjects 的高级语法树匹配
				custom_textobjects = {
					-- 函数参数 (Argument) -> 按键: a
					a = gen_spec.treesitter({ a = "@parameter.outer", i = "@parameter.inner" }),

					-- 条件判断 (If/Else) -> 按键: i
					i = gen_spec.treesitter({ a = "@conditional.outer", i = "@conditional.inner" }),

					-- 循环体 (For/While) -> 按键: l
					l = gen_spec.treesitter({ a = "@loop.outer", i = "@loop.inner" }),

					-- 函数调用 (Function Call) -> 按键: f
					f = gen_spec.treesitter({ a = "@call.outer", i = "@call.inner" }),

					-- 函数/方法定义 (Definition) -> 按键: m
					m = gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),

					-- 类定义 (Class) -> 按键: c
					c = gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
				},
			})

			-- ====================================================================
			-- 2. mini.surround 适配 (保持不变，gs 前缀非常安全)
			-- ====================================================================
			require("mini.surround").setup({
				mappings = {
					add = "gsa",
					delete = "gsd",
					find = "gsf",
					find_left = "gsF",
					highlight = "gsh",
					replace = "gsr",
					update_n_lines = "gsn",
				},
			})

			-- ====================================================================
			-- 3. mini.move 适配
			-- 核心思路：放弃大写 J/K/I/L 避免覆盖大幅移动，改用 Ctrl + 方向键
			-- ====================================================================
			require("mini.move").setup({
				mappings = {
					-- 视觉模式下的拖拽 (完美接管你配置中的第九部分)
					left = "<C-j>",
					down = "<C-k>",
					up = "<C-i>",
					right = "<C-l>",

					-- 普通模式下单行拖拽 (你之前设为空，如果不需要就保持空字符串)
					line_left = "",
					line_right = "",
					line_down = "",
					line_up = "",
				},
			})
		end,
	},
}
