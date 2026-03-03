return {
	-- =====================================================================
	-- 1. 语法树：安全注入 Python 相关解析器
	-- =====================================================================
	{
		"nvim-treesitter/nvim-treesitter",
		opts = function(_, opts)
			opts.ensure_installed = opts.ensure_installed or {}
			local py_parsers = { "python", "ninja", "rst", "toml" }
			if type(opts.ensure_installed) == "table" then
				for _, parser in ipairs(py_parsers) do
					if not vim.tbl_contains(opts.ensure_installed, parser) then
						table.insert(opts.ensure_installed, parser)
					end
				end
			end
		end,
	},

	-- =====================================================================
	-- 2. LSP 混合模式配置 (Pyright + Ruff)
	-- =====================================================================
	{
		"neovim/nvim-lspconfig",
		opts = function(_, opts)
			opts.servers = opts.servers or {}

			-- ❌ 防御性关闭已被废弃或不需要的服务器
			opts.servers.ruff_lsp = { enabled = false }
			opts.servers.basedpyright = { enabled = false }

			-- ==========================================
			-- [A] 激活 Pyright: 专职负责类型推断与代码跳转
			-- ==========================================
			opts.servers.pyright = opts.servers.pyright or {}
			opts.servers.pyright.settings = {
				python = {
					analysis = {
						autoSearchPaths = true,
						useLibraryCodeForTypes = true,
						-- 限制诊断范围，提高大型项目性能
						diagnosticMode = "openFilesOnly",
					},
				},
			}

			-- ==========================================
			-- [B] 激活 Ruff: 极速代码规范检查 (Linting)
			-- ==========================================
			opts.servers.ruff = opts.servers.ruff or {}
			opts.servers.ruff.init_options = {
				settings = {
					logLevel = "error",
				},
			}

			-- ==========================================
			-- [C] 精确拦截与快捷键注入 (保持与 TS 逻辑一致)
			-- ==========================================
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("python-custom-attach", { clear = true }),
				callback = function(args)
					local client = vim.lsp.get_client_by_id(args.data.client_id)
					local bufnr = args.buf

					if not client then
						return
					end

					-- 🌟 核心冲突解决：没收 Ruff 的 Hover 权限，全权交给 Pyright
					if client.name == "ruff" then
						client.server_capabilities.hoverProvider = false
					end

					-- 为 Ruff 单独注入一键修复和格式化的快捷键 (对齐 TypeScript 习惯)
					if client.name == "ruff" then
						local map = function(keys, func, desc)
							vim.keymap.set("n", keys, func, { buffer = bufnr, desc = "Ruff: " .. desc })
						end

						-- <leader>co: 一键自动整理 Import 排序
						map("<leader>co", function()
							vim.lsp.buf.code_action({
								apply = true,
								context = {
									only = { "source.organizeImports" },
									diagnostics = {},
								},
							})
						end, "Organize Imports")

						-- <leader>cD: 一键修复所有 Lint 报错 (如删掉未使用的变量)
						map("<leader>cD", function()
							vim.lsp.buf.code_action({
								apply = true,
								context = {
									only = { "source.fixAll" },
									diagnostics = {},
								},
							})
						end, "Fix All Diagnostics")
					end
				end,
			})
		end,
	},

	-- =====================================================================
	-- 3. 代码格式化 (Conform 接入)
	-- =====================================================================
	{
		"conform.nvim",
		opts = function(_, opts)
			opts.formatters_by_ft = opts.formatters_by_ft or {}

			-- 🌟 终极流水线：保存时 -> 自动修复 Lint (ruff_fix) -> 极速排版 (ruff_format)
			opts.formatters_by_ft.python = { "ruff_fix", "ruff_format", stop_after_first = false }
		end,
	},
}
