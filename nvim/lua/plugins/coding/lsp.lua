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
			-- =====================================================================
			-- 禁用默认快捷键
			-- =====================================================================
			local default_keys = { "gra", "grn", "grr", "gri", "grt" }
			for _, key in ipairs(default_keys) do
				pcall(vim.keymap.del, "n", key)
			end

			-- =====================================================================
			-- Telescope 全局搜索快捷键
			-- 修复说明：这些操作不依赖 LSP，且没有 buffer 限制，因此移出 LspAttach 避免重复注册
			-- =====================================================================
			vim.keymap.set("n", "gw", function()
				require("telescope.builtin").grep_string({ word_match = "-w" })
			end, { desc = "Telescope: [G]rep [W]ord under cursor" })

			vim.keymap.set("v", "gw", function()
				local saved_reg = vim.fn.getreg("v")
				vim.cmd('noau normal! "vy"')
				local text = vim.fn.getreg("v")
				vim.fn.setreg("v", saved_reg)

				require("telescope.builtin").grep_string({ search = text })
			end, { desc = "Telescope: Grep selected text" })

			vim.keymap.set("n", "gF", function()
				local current_file = vim.fn.expand("<cfile>")
				local clean_file = current_file:gsub("^[@~]/", "")
				require("telescope.builtin").find_files({ default_text = clean_file })
			end, { desc = "Telescope: Find [F]ile under cursor" })

			vim.keymap.set("v", "gF", function()
				local saved_reg = vim.fn.getreg("v")
				vim.cmd('noau normal! "vy"')
				local text = vim.fn.getreg("v")
				vim.fn.setreg("v", saved_reg)

				local clean_text = text:gsub("^[@~]/", "")
				require("telescope.builtin").find_files({ default_text = clean_text })
			end, { desc = "Telescope: Find selected [F]ile" })

			-- =====================================================================
			-- LSP Attach 事件处理 (处理跳转、重命名、高亮、内联提示)
			-- =====================================================================
			vim.api.nvim_create_autocmd("LspAttach", {
				group = vim.api.nvim_create_augroup("kickstart-lsp-attach", { clear = true }),
				callback = function(event)
					local client = vim.lsp.get_client_by_id(event.data.client_id)
					if not client then
						return
					end

					local map = function(keys, func, desc, mode)
						mode = mode or "n"
						vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = "LSP: " .. desc })
					end

					-- 1. 基础跳转与操作
					map("<leader>cr", vim.lsp.buf.rename, "[R]e[n]ame")
					map("<leader>ca", vim.lsp.buf.code_action, "Code Action", { "n", "x" })
					map("gh", vim.lsp.buf.hover, "Goto [H]over")
					map("<C-h>", vim.lsp.buf.hover, "[H]over", "i")
					map("gs", vim.lsp.buf.signature_help, "[S]ignature Help", "n")
					map("<C-g>", vim.lsp.buf.signature_help, "Signature Help", "i")
					map("gd", function()
						require("telescope.builtin").lsp_definitions({ reuse_win = true })
					end, "Goto Definition")

					map("gr", function()
						require("telescope.builtin").lsp_references({
							include_current_line = false,
							file_ignore_patterns = {},
						})
					end, "Goto References")

					map("gI", function()
						require("telescope.builtin").lsp_implementations({ reuse_win = true })
					end, "Goto Implementation")

					-- 2. 类型定义跳转 (TypeScript / Vue 开发神器)
					if client:supports_method(vim.lsp.protocol.Methods.textDocument_typeDefinition, event.buf) then
						map("gt", function()
							require("telescope.builtin").lsp_type_definitions({ reuse_win = true })
						end, "Goto T[y]pe Definition")
					end

					-- 3. 相同符号自动高亮
					if client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight, event.buf) then
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

					-- 4. 内联提示切换开关
					if client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint, event.buf) then
						map("<leader>th", function()
							vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = event.buf }))
						end, "Toggle Inlay Hints")
					end
				end,
			})

			-- =====================================================================
			-- 核心能力合并 (Capabilities)
			-- =====================================================================
			local capabilities = require("blink.cmp").get_lsp_capabilities()
			capabilities.textDocument.foldingRange = {
				dynamicRegistration = false,
				lineFoldingOnly = true,
			}

			-- =====================================================================
			-- Mason 统一工具安装管理
			-- =====================================================================
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

			-- =====================================================================
			-- 极致原生的发射舱 (遍历启动服务器)
			-- =====================================================================
			for name, server_config in pairs(opts.servers or {}) do
				-- 拦截检查：过滤掉被模块化文件声明为 { enabled = false } 的服务器
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
