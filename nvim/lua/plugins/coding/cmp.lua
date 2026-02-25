return { -- Autocompletion
	"saghen/blink.cmp",
	event = "VimEnter",
	version = "1.*",
	dependencies = {
		-- 依然保留 LuaSnip 作为底层的 Snippet 引擎
		{
			"L3MON4D3/LuaSnip",
			version = "2.*",
			build = (function()
				if vim.fn.has("win32") == 1 or vim.fn.executable("make") == 0 then
					return
				end
				return "make install_jsregexp"
			end)(),
			dependencies = {
				-- 如果你想启用 friendly-snippets，取消下面的注释即可
				-- {
				--   'rafamadriz/friendly-snippets',
				--   config = function()
				--     require('luasnip.loaders.from_vscode').lazy_load()
				--   end,
				-- },
			},
			opts = {},
		},
	},
	--- @module 'blink.cmp'
	--- @type blink.cmp.Config
	opts = {
		keymap = {
			-- 'default' 预设已经包含了你熟悉的 <C-n>, <C-p>, <C-y> (确认), <C-Space> (触发)
			preset = "none",
			["<CR>"] = { "accept", "fallback" },
			["<Tab>"] = {
				function(cmp)
					if cmp.snippet_active() then
						return cmp.accept()
					else
						return cmp.select_and_accept()
					end
				end,
				"snippet_forward",
				"fallback",
			},
			["<S-Tab>"] = { "snippet_backward", "fallback" },
			["<C-h>"] = { "show_signature", "hide_signature", "fallback" },
			-- 建议适配你的 jkli 布局进行补全项选择
			["<C-i>"] = { "select_prev", "fallback" },
			["<C-k>"] = { "select_next", "show_signature", "fallback" },
			-- 补充你旧配置中的文档滚动
			["<C-u>"] = { "scroll_documentation_up", "fallback" },
			["<C-d>"] = { "scroll_documentation_down", "fallback" },

			-- 补充你旧配置中的 Snippet 节点跳转逻辑 (用 <C-l> 前进，<C-h> 后退)
			["<C-l>"] = { "snippet_forward", "fallback" },
			["<C-j>"] = { "snippet_backward", "fallback" },
			["<C-Space>"] = { "show", "show_documentation", "hide_documentation", "fallback" },
		},

		appearance = {
			nerd_font_variant = "mono",
		},

		completion = {
			documentation = { auto_show = true, auto_show_delay_ms = 500 },
			-- 补全菜单的显示逻辑与旧版 completeopt = 'menu,menuone,noinsert' 类似，blink 原生已经优化得很好
			accept = {
				-- 开启原生极速括号补全
				auto_brackets = {
					enabled = true,
				},
			},
		},

		sources = {
			-- 核心改动：在这里把 lazydev 加入到默认源中
			default = { "lazydev", "lsp", "path", "snippets", "buffer" },
			providers = {
				-- 配置 lazydev 专属提供者
				lazydev = {
					name = "LazyDev",
					module = "lazydev.integrations.blink",
					-- score_offset 相当于旧版 cmp 的 group_index = 0，让 Neovim API 的补全优先级最高
					score_offset = 100,
				},
			},
		},

		snippets = { preset = "luasnip" },

		fuzzy = {
			implementation = "prefer_rust",
		}, -- 推荐开启 Rust 模糊匹配，速度极快

		signature = { enabled = true },
	},
	config = function(_, opts)
		require("blink.cmp").setup(opts)
		local blink = require("blink.cmp")

		-- 2. Normal 模式下的 Toggle 逻辑
		vim.keymap.set("n", "<C-h>", function()
			if blink.is_signature_visible() then
				blink.hide_signature()
			else
				blink.show_signature()
			end
		end, { desc = "Blink: Toggle Signature" })
	end,
}
