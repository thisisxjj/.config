return {
	"windwp/nvim-ts-autotag",
	-- 作为输入拦截类插件，按需加载能极大提升 Neovim 启动速度
	ft = {
		"javascript",
		"typescript",
		"javascriptreact",
		"typescriptreact",
		"vue",
		"tsx",
		"jsx",
		"html",
		"xml",
		"astro",
	},
	config = function()
		require("nvim-ts-autotag").setup({
			opts = {
				enable_close = true, -- 输入 > 自动生成闭合标签
				enable_rename = true, -- 🌟 神技：改开头标签，结尾标签同步自动修改
				enable_close_on_slash = true, -- 输入 </ 时，自动补全未闭合的标签
			},
		})
	end,
}
