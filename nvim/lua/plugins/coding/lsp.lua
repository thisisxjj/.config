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
				intelephense = {},
				neocmake = {},
				tailwindcss = {},
				volar = {},
				-- vtsls 作为空桩位，准备接收 typescript.lua 和 astro.lua 的插件注入
				vtsls = {},

				-- 模块化内聚：ESLint 特殊配置
				eslint = {
					settings = { workingDirectory = { mode = "auto" } },
					on_attach = function(client, bufnr)
						client.server_capabilities.documentFormattingProvider = false
						vim.api.nvim_buf_create_user_command(bufnr, "EslintFixAll", function()
							client.request("workspace/executeCommand", {
								command = "eslint.applyAllFixes",
								arguments = { { uri = vim.uri_from_bufnr(bufnr) } },
							})
						end, { desc = "ESLint: Fix all autofixable problems" })
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
			-- 1. 全局 LspAttach (处理跳转、重命名，以及高亮和内联提示)
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					map("grn", vim.lsp.buf.rename, "[R]e[n]ame")
					map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "x" })
					map("gd", vim.lsp.buf.definition, "Goto Definition")
					map("gr", vim.lsp.buf.references, "Goto Declaration")

					local client = vim.lsp.get_client_by_id(event.data.client_id)
					-- 1. 跳转到声明 (C/C++常用，TS/JS不支持)
					-- 2. 跳转到类型定义 (TypeScript / Vue 开发神器！)
					-- 当你的光标在一个变量上时，跳到定义它 TS 接口 (Interface/Type) 的地方
					if
						client
						and client:supports_method(vim.lsp.protocol.Methods.textDocument_typeDefinition, event.buf)
					then
						map("gt", vim.lsp.buf.type_definition, "Goto T[y]pe Definition")
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
