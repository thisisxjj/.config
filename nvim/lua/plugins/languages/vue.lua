return {
	-- 1. 语法树：确保安装 Vue 解析器
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			if type(opts.ensure_installed) == "table" and not vim.tbl_contains(opts.ensure_installed, "vue") then
				table.insert(opts.ensure_installed, "vue")
			end
		end,
	},

	-- 2. LSP 混合模式核心配置 (vue_ls + vtsls)
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}

			-- ==========================================
			-- [A] 激活 vue_ls (并注入 tsdk 防报错)
			-- ==========================================
			opts.servers.vue_ls = {
				init_options = {
					vue = {
						hybridMode = true,
					},
					typescript = {
						tsdk = (function()
							-- 优先找项目本地 TS，兜底找 Mason 全局 TS
							local local_ts = vim.fn.getcwd() .. "/node_modules/typescript/lib"
							if vim.fn.isdirectory(local_ts) == 1 then
								return local_ts
							end
							return (vim.env.MASON or (vim.fn.stdpath("data") .. "/mason"))
								.. "/packages/vtsls/node_modules/typescript/lib"
						end)(),
					},
				},
			}

			-- ==========================================
			-- [B] 联动 VTSLS：接管 <script> 区域
			-- ==========================================
			opts.servers.vtsls = opts.servers.vtsls or {}
			opts.servers.vtsls.filetypes = opts.servers.vtsls.filetypes or {}

			-- 动态追加 vue 到监听列表，不覆盖基础 JS/TS
			if not vim.tbl_contains(opts.servers.vtsls.filetypes, "vue") then
				table.insert(opts.servers.vtsls.filetypes, "vue")
			end

			-- 安全初始化深层表结构
			opts.servers.vtsls.settings = opts.servers.vtsls.settings or {}
			opts.servers.vtsls.settings.vtsls = opts.servers.vtsls.settings.vtsls or {}
			opts.servers.vtsls.settings.vtsls.tsserver = opts.servers.vtsls.settings.vtsls.tsserver or {}
			opts.servers.vtsls.settings.vtsls.tsserver.globalPlugins = opts.servers.vtsls.settings.vtsls.tsserver.globalPlugins
				or {}

			-- 防止多次加载重复注入插件
			local has_vue_plugin = false
			for _, plugin in ipairs(opts.servers.vtsls.settings.vtsls.tsserver.globalPlugins) do
				if plugin.name == "@vue/typescript-plugin" then
					has_vue_plugin = true
					break
				end
			end

			-- 注入 Vue TS 插件（带最高权限解除）
			if not has_vue_plugin then
				local mason_registry = vim.env.MASON or (vim.fn.stdpath("data") .. "/mason")
				table.insert(opts.servers.vtsls.settings.vtsls.tsserver.globalPlugins, {
					name = "@vue/typescript-plugin",
					location = mason_registry .. "/packages/vue-language-server/node_modules/@vue/language-server",
					languages = { "vue" },
					configNamespace = "typescript",
					-- 🚨 解决 can't find name script 报错的核心救命代码
					enableForWorkspaceTypeScriptVersions = true,
				})
			end
		end,
	},

	-- 3. 格式化配置：优先极速守护进程，兜底原生 Prettier
	{
		"conform.nvim",
		opts = function(_, opts)
			opts.formatters_by_ft = opts.formatters_by_ft or {}
			opts.formatters_by_ft.vue = { "prettierd", "prettier", stop_after_first = true }
		end,
	},
}
