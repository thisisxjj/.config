return {
	-- =====================================================================
	-- 核心 LSP 配置
	-- =====================================================================
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			{ "j-hui/fidget.nvim", opts = {} },
			-- =====================================================================
			-- Lua 开发的最强辅助：自动注入 Neovim API 与插件类型
			-- =====================================================================
			{
				"folke/lazydev.nvim",
				ft = "lua",
				opts = {
					library = {
						{ path = "${3rd}/luv/library", words = { "vim%.uv" } },
					},
				},
			},
			"saghen/blink.cmp",
		},
		-- =====================================================================
		-- 基础配置盘 (Baseline)
		-- =====================================================================
		opts = {
			servers = {
				astro = {},
				cssls = {},
				pyright = {},
				ruff = {},
				intelephense = {},
				neocmake = {},
				tailwindcss = {},
				vue_ls = {},
				-- vtsls 作为空桩位，准备接收 typescript.lua 和 astro.lua 的插件注入
				vtsls = {},

				-- 模块化内聚：ESLint 特殊配置
				eslint = {
					settings = { workingDirectory = { mode = "auto" } },
					on_attach = function(client, bufnr)
						-- 1. 禁用 ESLint 的格式化能力，将排版权柄完全交给 Prettier
						client.server_capabilities.documentFormattingProvider = false

						-- 2. 注册一键修复命令
						vim.api.nvim_buf_create_user_command(bufnr, "EslintFixAll", function()
							client.request("workspace/executeCommand", {
								command = "eslint.applyAllFixes",
								arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
							})
						end, { desc = "ESLint: Fix all autofixable problems" })

						-- 🌟 核心新增：监听文件保存事件，自动执行上面的修复命令
						vim.api.nvim_create_autocmd("BufWritePre", {
							buffer = bufnr,
							command = "EslintFixAll",
						})
					end,
				},

				-- 模块化内聚：Lua_ls 特殊配置
				lua_ls = {
					settings = {
						Lua = {
							completion = { callSnippet = "Replace" },
							diagnostics = { globals = { "vim" }, disable = { "missing-fields" } },
						},
					},
				},
			},
		},
		config = function(_, opts)
			-- 禁用 gr 开头默认快捷键
			pcall(vim.keymap.del, "n", "gra")
			pcall(vim.keymap.del, "n", "grn")
			pcall(vim.keymap.del, "n", "grr")
			pcall(vim.keymap.del, "n", "gri")
			pcall(vim.keymap.del, "n", "grt")
			-- 1. 全局 LspAttach (处理跳转、重命名，以及高亮和内联提示)
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					map("<leader>rn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "x" })
					map("gh", vim.lsp.buf.hover, "[H]over")
					-- gd: 跳转到定义
					map("gd", vim.lsp.buf.definition, "Goto Definition")

					-- 1. 你原有的 Normal 模式 gw (查普通单词)
					vim.keymap.set("n", "gw", function()
						require("telescope.builtin").grep_string({ word_match = "-w" })
					end, { desc = "Telescope: [G]rep [W]ord under cursor" })

					-- 2. 🌟 新增的 Visual 模式 gw (查带有特殊符号的路径/长字符串)
					vim.keymap.set("v", "gw", function()
						-- 极客黑魔法：瞬间把选中的文本复制到寄存器，再喂给 Telescope，然后把寄存器恢复原样
						local saved_reg = vim.fn.getreg("v")
						vim.cmd('noau normal! "vy"')
						local text = vim.fn.getreg("v")
						vim.fn.setreg("v", saved_reg)

						require("telescope.builtin").grep_string({ search = text })
					end, { desc = "Telescope: Grep selected text" })
					local builtin = require("telescope.builtin")

					-- 1. Normal 模式：自动抓取光标下的路径，并在文件树中模糊搜索
					vim.keymap.set("n", "gF", function()
						-- <cfile> 是 Vim 原生专门用来抓取光标下"文件路径"的黑魔法
						local current_file = vim.fn.expand("<cfile>")

						-- 顺手清理一下可能抓到的无用前缀（比如前端常用的 @/ 或 ~）
						-- 这样 Telescope 就能纯粹用后面的真实文件名去 fuzzy match
						local clean_file = current_file:gsub("^[@~]/", "")

						builtin.find_files({ default_text = clean_file })
					end, { desc = "Telescope: Find [F]ile under cursor" })

					-- 2. Visual 模式：选中任意一段长路径直接搜文件
					vim.keymap.set("v", "gF", function()
						local saved_reg = vim.fn.getreg("v")
						vim.cmd('noau normal! "vy"')
						local text = vim.fn.getreg("v")
						vim.fn.setreg("v", saved_reg)

						local clean_text = text:gsub("^[@~]/", "")
						builtin.find_files({ default_text = clean_text })
					end, { desc = "Telescope: Find selected [F]ile" })
					-- gr: 跳转到引用 (修复了之前的 desc 描述)
					map("gr", function()
						require("telescope.builtin").lsp_references({
							include_current_line = false,
							file_ignore_patterns = {},
						})
					end, "Goto References")

					-- gI: 跳转到实现 (面向对象语言中极其好用)
					map("gI", function()
						require("telescope.builtin").lsp_implementations({ reuse_win = true })
					end, "Goto Implementation")

					local client = vim.lsp.get_client_by_id(event.data.client_id)
					-- gt: 跳转到类型定义 (TypeScript / Vue 开发神器！)
					if
						client
						and client:supports_method(vim.lsp.protocol.Methods.textDocument_typeDefinition, event.buf)
					then
						map("gt", function()
							require("telescope.builtin").lsp_type_definitions({ reuse_win = true })
						end, "Goto T[y]pe Definition")
					end
					-- === 相同符号自动高亮 (使用标准常量) ===
					if
						client
						and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf)
					then
						local highlight_augroup =
							vim.api.nvim_create_augroup("kickstart-lsp-highlight", { clear = false })

						vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.document_highlight,
						})

						vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
							buffer = event.buf,
							group = highlight_augroup,
							callback = vim.lsp.buf.clear_references,
						})

						vim.api.nvim_create_autocmd("LspDetach", {
							group = vim.api.nvim_create_augroup("kickstart-lsp-detach", { clear = true }),
							callback = function(event2)
								vim.lsp.buf.clear_references()
								vim.api.nvim_clear_autocmds({ group = "kickstart-lsp-highlight", buffer = event2.buf })
							end,
						})
					end

					-- === 内联提示切换开关 (使用标准常量) ===
					if
						client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf)
					then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "Toggle Inlay Hints")
					end
				end,
			})

			-- 2. 核心能力合并 (Capabilities)
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}

			-- 3. Mason 统一工具安装管理
			require("mason-tool-installer").setup({
				ensure_installed = {
					-- 语言服务器 (LSP)
					"astro-language-server",
					"css-lsp",
					"pyright",
					"intelephense",
					"neocmakelsp",
					"tailwindcss-language-server",
					"vtsls",
					"eslint-lsp",
					"lua-language-server",
					"docker-compose-language-service",
					"dockerfile-language-server",
					"vue-language-server",

					-- 格式化器与 Linter
					"biome",
					"hadolint",
					"prettier",
					"prettierd",
					"ruff",
					"stylua",

					-- 调试器 (DAP)
					"debugpy",
					"delve",
					"js-debug-adapter",
					"php-debug-adapter",
				},
			})

			-- 4. 极致原生的发射舱 (遍历所有合并好的 opts.servers 并在底层启动)
			for name, server_config in pairs(opts.servers or {}) do
				-- 💡 拦截检查：过滤掉被模块化文件声明为 { enabled = false } 的服务器 (如 tsserver)
				if server_config.enabled ~= false then
					server_config.capabilities =
						vim.tbl_deep_extend("force", {}, capabilities, server_config.capabilities or {})
					vim.lsp.config(name, server_config)
					vim.lsp.enable(name)
				end
			end
		end,
	},
}
