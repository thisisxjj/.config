return {
	"windwp/nvim-autopairs",
	event = "InsertEnter",
	config = function()
		require("nvim-autopairs").setup({
			-- 基础配置（通常默认即可，你也可以在这里自定义）

			-- 比如：在 Telescope 搜索框等特殊插件里，不触发自动括号
			disable_filetype = { "TelescopePrompt", "spectre_panel" },

			-- 比如：开启在 HTML/Vue 中按回车时，连带着把标签内的光标缩进处理好
			enable_check_bracket_line = false,
		})
	end,
}
