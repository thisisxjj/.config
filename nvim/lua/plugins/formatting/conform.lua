return {
	{
		"stevearc/conform.nvim",
		-- 监听保存事件，确保插件在保存前加载
		event = { "BufWritePre" },
		cmd = { "ConformInfo", "FormatToggle" },
		-- ==========================================================
		-- 快捷键配置区域
		-- ==========================================================
		keys = {
			-- 保留手动触发作为兜底
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				mode = "",
				desc = "Code Format",
			},

			-- 🌟 核心新增 1：临时禁用/启用【当前文件】的自动格式化 (Toggle Format)
			{ "<leader>tf", "<cmd>FormatToggle<cr>", mode = "n", desc = "Toggle Autoformat (Buffer)" },

			-- 🌟 核心新增 2：彻底禁用/启用【全局所有文件】的自动格式化
			{ "<leader>tF", "<cmd>FormatToggle!<cr>", mode = "n", desc = "Toggle Autoformat (Global)" },
		},

		opts = function()
			return {
				-- 工具映射表 (保持之前的极简回退链)
				formatters_by_ft = {
					lua = { "stylua" },
					php = { "pint" },
					blade = { "blade-formatter" },
					javascript = { "biome", "prettierd", "prettier", stop_after_first = true },
					javascriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
					typescript = { "biome", "prettierd", "prettier", stop_after_first = true },
					typescriptreact = { "biome", "prettierd", "prettier", stop_after_first = true },
					json = { "biome", "prettierd", "prettier", stop_after_first = true },
					jsonc = { "biome", "prettierd", "prettier", stop_after_first = true },
					css = { "biome", "prettierd", "prettier", stop_after_first = true },
					graphql = { "prettierd", "prettier", stop_after_first = true },
					html = { "prettierd", "prettier", stop_after_first = true },
					less = { "prettierd", "prettier", stop_after_first = true },
					scss = { "prettierd", "prettier", stop_after_first = true },
					vue = { "prettierd", "prettier", stop_after_first = true },
					yaml = { "prettierd", "prettier", stop_after_first = true },
					astro = { "prettierd", "prettier", stop_after_first = true },
				},

				-- ==========================================================
				-- 🌟 自动触发的核心逻辑 🌟
				-- 每次你按下 `:w` 都会执行这里。它会检查开关状态。
				-- ==========================================================
				format_on_save = function(bufnr)
					-- 检查是否按下了快捷键触发了禁用逻辑
					if vim.g.disable_autoformat or vim.b[bufnr].disable_autoformat then
						return -- 如果禁用了，直接静默退出，什么都不做
					end

					-- 否则，自动执行格式化
					return {
						timeout_ms = 2000,
						lsp_format = "fallback",
					}
				end,

				formatters = {
					biome = {
						condition = function(_, ctx)
							return vim.fs.find({ "biome.json", "biome.jsonc" }, { upward = true, path = ctx.dirname })[1]
								~= nil
						end,
					},
				},
			}
		end,

		config = function(_, opts)
			require("conform").setup(opts)

			-- 注册底层开关命令，并加入友好的屏幕提示
			vim.api.nvim_create_user_command("FormatToggle", function(args)
				local is_global = args.bang
				if is_global then
					vim.g.disable_autoformat = not vim.g.disable_autoformat
					local status = vim.g.disable_autoformat and "🔴 已禁用 (Disabled)"
						or "🟢 已启用 (Enabled)"
					vim.notify("全局自动格式化: " .. status, vim.log.levels.INFO, { title = "Conform" })
				else
					vim.b.disable_autoformat = not vim.b.disable_autoformat
					local status = vim.b.disable_autoformat and "🔴 已禁用 (Disabled)"
						or "🟢 已启用 (Enabled)"
					vim.notify("当前文件自动格式化: " .. status, vim.log.levels.INFO, { title = "Conform" })
				end
			end, { desc = "Toggle autoformat on save", bang = true })
		end,
	},
}
